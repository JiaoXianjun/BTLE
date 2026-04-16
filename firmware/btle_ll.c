// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2025 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

#define _GNU_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <stdint.h>
#include <poll.h>

#include <sched.h>
#include <pthread.h>
#include <ctype.h>
#include <errno.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sys/resource.h>

#include <sys/socket.h>
#include <netinet/ether.h>
#include <netpacket/packet.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <arpa/inet.h>

#include <sys/prctl.h>
#include <sys/wait.h>

#include <inttypes.h>

// #define BTLE_LL_REG_BASE 0x40000000
#define BTLE_LL_REG_SIZE 0x1000

#define BTLE_LL_REG_RX_UNIQUE_BIT_SEQ_IDX 10
#define BTLE_LL_REG_RX_CHANNEL_NUMBER_IDX 11
#define BTLE_LL_REG_RX_CRC_INIT_BIT_IDX   12
#define BTLE_LL_REG_RX_PDU_MEM_ADDR_IDX   13

#define FREQ_HZ_STRING_BUF_SIZE 32

#define BRAM_BASE_ADDR  0x80000000
#define BRAM_SIZE       0x20000   // 128 KB

#define SAMPLING_RATE_HZ 8000000
#define NUM_BYTES_PER_IQ_SAMPLE 4 // 2 bytes for I, 2 bytes for Q

#define BRAM_SIZE_HALF (BRAM_SIZE/2)
#define BRAM_SIZE_IN_WORD (BRAM_SIZE/NUM_BYTES_PER_IQ_SAMPLE)
#define BRAM_SIZE_IN_WORD_HALF (BRAM_SIZE_IN_WORD/2)

// #define DEBUG_PRINT(...) printf(__VA_ARGS__)
#define DEBUG_PRINT(...)

char ad9361_rx0_lo_file[] = "/sys/bus/iio/devices/iio:device0/out_altvoltage0_RX_LO_frequency";

int fd_uio = 0;
int fd_ram = 0;
int irq_count = 0;

int sockfd = 0;
struct sockaddr_ll socket_address;
uint8_t eth_raw_socket_buffer[1536];
uint8_t eth_raw_socket_buffer_child_ack_to_host[32];

int sockfd_child;

volatile sig_atomic_t signal_stop = 0;  // flag set by signal handler
volatile sig_atomic_t signal_stop_child = 0;  // flag set by signal handler

volatile uint32_t *fpga_regs;
volatile uint32_t *bram_ptr;

static inline void handle_sigint(int sig) {
  int tmp_for_irq_re_arm = 1;
  signal_stop = 1;  // just set the flag, keep it simple & async-signal-safe

  if (write(fd_uio, &tmp_for_irq_re_arm, sizeof(tmp_for_irq_re_arm)) != sizeof(tmp_for_irq_re_arm)) {
    perror("write");
  }

  printf("Quitting...\n");
}

static inline void handle_sigint_child(int sig) {
  signal_stop_child = 1;  // just set the flag, keep it simple & async-signal-safe

  if (fcntl(sockfd_child, F_GETFD) == -1 && errno == EBADF) {
    printf("child: handle_sigint socket is closed in this process already\n");
  } else {
    printf("child: handle_sigint socket FD is still open\n");
    close(sockfd_child);
  }

  printf("Quitting child...\n");
}

static inline void pin_to_cpu(int cpu_id) {
  cpu_set_t mask;
  CPU_ZERO(&mask);
  CPU_SET(cpu_id, &mask);
  if (sched_setaffinity(0, sizeof(mask), &mask) != 0) {
    perror("sched_setaffinity");
    exit(1);
  }
  DEBUG_PRINT(printf("Pinned to CPU %d\n", cpu_id);)
}

static inline void set_realtime_priority(void) {
  struct sched_param param;
  param.sched_priority = 99;  // Highest RT prio
  if (sched_setscheduler(0, SCHED_FIFO, &param) != 0) {
    perror("sched_setscheduler");
    exit(1);
  }
  DEBUG_PRINT(printf("Real-time priority set (SCHED_FIFO, prio 99)\n");)
}

static inline int set_irq_affinity(int irq, const char *mask)
{
  char path[128];
  snprintf(path, sizeof(path), "/proc/irq/%d/smp_affinity", irq);

  FILE *fp = fopen(path, "w");
  if (!fp) {
    perror("Failed to open smp_affinity");
    // exit(1);
    return 1;
  }

  if (fprintf(fp, "%s\n", mask) < 0) {
    perror("Failed to write to smp_affinity");
    fclose(fp);
    // exit(1);
    return 1;
  }

  fclose(fp);
  return 0;
}

static inline uint64_t get_time_us() {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts); // Monotonic: not affected by system clock changes
  return (uint64_t)ts.tv_sec * 1000000ULL + ts.tv_nsec / 1000;
}

static inline uint32_t get_time_s() {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts); // Monotonic: not affected by system clock changes
  return (uint32_t)ts.tv_sec;
}

static inline int eth_raw_socket_init(char *ifname, unsigned char *dest_mac) {
  struct ifreq if_idx;
  struct ifreq if_mac;

  // const char *ifname = "eth0"; // your Ethernet interface
  // const unsigned char dest_mac[6] = {0xf4, 0x6b, 0x8c, 0x01, 0x61, 0x84}; // B's MAC address
  const unsigned short ether_type = 0x88B5; // custom ethertype

  // 1. Open raw socket
  sockfd = socket(AF_PACKET, SOCK_RAW, htons(ether_type));
  if (sockfd < 0) { perror("socket"); return -1; }

  // 2. Get interface index
  memset(&if_idx, 0, sizeof(struct ifreq));
  strncpy(if_idx.ifr_name, ifname, IFNAMSIZ - 1);
  ioctl(sockfd, SIOCGIFINDEX, &if_idx);

  // 3. Get interface MAC
  memset(&if_mac, 0, sizeof(struct ifreq));
  strncpy(if_mac.ifr_name, ifname, IFNAMSIZ - 1);
  ioctl(sockfd, SIOCGIFHWADDR, &if_mac);

  // 4. Build Ethernet frame
  struct ether_header *eh = (struct ether_header *) eth_raw_socket_buffer;
  memcpy(eh->ether_shost, if_mac.ifr_hwaddr.sa_data, 6);
  memcpy(eh->ether_dhost, dest_mac, 6);
  eh->ether_type = htons(ether_type);
  // 4. Build Ethernet frame for child process ACK to host
  eh = (struct ether_header *) eth_raw_socket_buffer_child_ack_to_host;
  memcpy(eh->ether_shost, if_mac.ifr_hwaddr.sa_data, 6);
  memcpy(eh->ether_dhost, dest_mac, 6);
  eh->ether_type = htons(ether_type);

  // // 5. Add payload (your binary data)
  // const char payload[] = "HelloBinary";
  // int payload_len = sizeof(payload);
  // memcpy(eth_raw_socket_buffer + sizeof(struct ether_header), payload, payload_len);

  // 6. Prepare sockaddr_ll
  memset(&socket_address, 0, sizeof(struct sockaddr_ll));
  socket_address.sll_ifindex = if_idx.ifr_ifindex;
  socket_address.sll_halen = ETH_ALEN;

  // // 3. Get interface MAC
  // memset(&if_mac, 0, sizeof(struct ifreq));
  // strncpy(if_mac.ifr_name, ifname, IFNAMSIZ - 1);
  // ioctl(sockfd, SIOCGIFHWADDR, &if_mac);

  // // 4. Build Ethernet frame
  // eh = (struct ether_header *) eth_raw_socket_buffer;
  // memcpy(eh->ether_shost, if_mac.ifr_hwaddr.sa_data, 6);
  // memcpy(eh->ether_dhost, dest_mac, 6);
  // eh->ether_type = htons(ether_type);

  // // 5. Add payload (your binary data)
  // const char payload[] = "HelloBinary";
  memcpy(socket_address.sll_addr, dest_mac, 6);

  return 0;
}

// timestamp resolution: 1/bb_clk = 1/16 us = 62.5 ns
static inline int eth_raw_socket_send(uint64_t timestamp, uint32_t access_address, uint32_t header_payload_crc_len, char *packet_byte, uint32_t num_byte_total) {
  const uint32_t eth_header_len = sizeof(struct ether_header);
  const uint32_t magic_header_len = 4;
  const uint32_t timestamp_len = 8;
  const uint32_t access_address_len = 4;
  const uint32_t length_field_len = 4;
  uint32_t runtime_len;

  runtime_len = eth_header_len;
  // 4 bytes magic header
  ((uint32_t*)(eth_raw_socket_buffer + runtime_len))[0] = 0x05628562;

  runtime_len = runtime_len + magic_header_len;
  // 8 bytes timestamp
  ((uint64_t*)(eth_raw_socket_buffer + runtime_len))[0] = timestamp;

  runtime_len = runtime_len + timestamp_len;
  // 4 bytes access_address
  ((uint32_t*)(eth_raw_socket_buffer + runtime_len))[0] = access_address;

  runtime_len = runtime_len + access_address_len;
  // 4 bytes header_payload_crc_len
  ((uint32_t*)(eth_raw_socket_buffer + runtime_len))[0] = header_payload_crc_len;

  runtime_len = runtime_len + length_field_len;
  // Copy packet_byte after magic header and Ethernet header
  memcpy(eth_raw_socket_buffer + runtime_len, packet_byte, num_byte_total);

  runtime_len = runtime_len + num_byte_total;
  // Send the packet
  int send_result = sendto(sockfd, eth_raw_socket_buffer, runtime_len, 0,
                           (struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll));
  if (send_result < 0)
    perror("sendto");

  return send_result;
}

static inline uint64_t channel_number_to_freq_Hz(uint32_t channel_number) {
  uint64_t freq_Hz;
  if ( channel_number == 37 ) {
    freq_Hz = 2402000000ull;
  } else if (channel_number == 38) {
    freq_Hz = 2426000000ull;
  } else if (channel_number == 39) {
    freq_Hz = 2480000000ull;
  } else if (channel_number >=0 && channel_number <= 10 ) {
    freq_Hz = 2404000000ull + channel_number*2000000ull;
  } else if (channel_number >=11 && channel_number <= 36 ) {
    freq_Hz = 2428000000ull + (channel_number-11)*2000000ull;
  } else {
    freq_Hz = 0xffffffffffffffff;
  }
  return(freq_Hz);
}

static inline void freq_Hz_to_string(uint64_t freq_Hz, char *freq_str) {
  snprintf(freq_str, FREQ_HZ_STRING_BUF_SIZE, "%" PRIu64, freq_Hz);
}

static inline int host_intf(void) {
  uint8_t buffer_child[1536];
  const char *ifname_child = "eth0";
  const unsigned short ether_type_child = 0x88B5;
  const uint32_t eth_header_len_child = sizeof(struct ether_header);

  char freq_str[FREQ_HZ_STRING_BUF_SIZE];

  static const uint32_t magic_header_len = 4;
  static const uint32_t timestamp_len = 8;
  static const uint32_t control_len = 4;
  static const uint32_t unit_field_len = 4;
  uint32_t runtime_len = 0, magic_header, control, unit_field0, unit_field1;
  uint32_t total_len = eth_header_len_child + magic_header_len + timestamp_len + control_len + 2*unit_field_len;
  uint32_t ack_len = eth_header_len_child + magic_header_len; // 4 bytes ACK magic header
  uint64_t timestamp;

  sockfd_child = socket(AF_PACKET, SOCK_RAW, htons(ether_type_child));
  if (sockfd_child < 0) { perror("child: socket"); return 1; }

  struct ifreq ifr;
  memset(&ifr, 0, sizeof(ifr));
  strncpy(ifr.ifr_name, ifname_child, IFNAMSIZ - 1);
  ioctl(sockfd_child, SIOCGIFINDEX, &ifr);

  struct sockaddr_ll saddr = {0};
  saddr.sll_family = AF_PACKET;
  saddr.sll_protocol = htons(ether_type_child);
  saddr.sll_ifindex = ifr.ifr_ifindex;

  if (bind(sockfd_child, (struct sockaddr*)&saddr, sizeof(saddr)) < 0) {
    perror("child: bind");
    close(sockfd_child);
    return 1;
  }

  // 4 bytes magic header to label ACK packet to host
  ((uint32_t*)(eth_raw_socket_buffer_child_ack_to_host + eth_header_len_child))[0] = 0x19293811;

  while (signal_stop_child == 0) {
    ssize_t numbytes = recvfrom(sockfd_child, buffer_child, sizeof(buffer_child), 0, NULL, NULL);
    if (numbytes > 0) {
      // printf("child: Received %zd bytes: ", numbytes);
      // for (int i = eth_header_len_child; i < numbytes; i++)
      //     printf("%02x ", buffer_child[i]);
      // printf("\n");
      if (numbytes < total_len) {
        printf("child: Packet too short (%zd bytes < %zd bytes), ignoring\n", numbytes, total_len);
        continue;
      }

      runtime_len = eth_header_len_child;
      // 4 bytes magic header
      magic_header = ((uint32_t*)(buffer_child + runtime_len))[0];

      if (magic_header == 0x64838364) {
        runtime_len = runtime_len + magic_header_len;
        // 8 bytes timestamp
        timestamp = ((uint64_t*)(buffer_child + runtime_len))[0];

        runtime_len = runtime_len + timestamp_len;
        // 4 bytes access_address
        control = ((uint32_t*)(buffer_child + runtime_len))[0];

        if (control == 0) { // set register
          runtime_len = runtime_len + control_len;
          // 4 bytes unit_field0
          unit_field0 = ((uint32_t*)(buffer_child + runtime_len))[0];

          runtime_len = runtime_len + unit_field_len;
          // 4 bytes unit_field1
          unit_field1 = ((uint32_t*)(buffer_child + runtime_len))[0];

          fpga_regs[unit_field0] = unit_field1;

          if (unit_field0 == BTLE_LL_REG_RX_CHANNEL_NUMBER_IDX) { // change ad9361 rx frequency
            FILE *fp = fopen(ad9361_rx0_lo_file, "w");
            if (!fp) {
                perror("child: fopen ad9361_rx0_lo_file");
                close(sockfd_child);
                return 1;
            }
            
            uint64_t freq_Hz = channel_number_to_freq_Hz(unit_field1);
            freq_Hz_to_string(freq_Hz, freq_str);
            printf("child: set %s to %s Hz for channel number %d\n", ad9361_rx0_lo_file, freq_str, unit_field1);
            timestamp = get_time_us();
            if (fprintf(fp, "%s", freq_str) < 0) {
                perror("child: fprintf ad9361_rx0_lo_file");
                fclose(fp);
                close(sockfd_child);
                return 1;
            }
            timestamp = get_time_us() - timestamp;
            printf("child: write frequency took %lluus\n", (unsigned long long)timestamp);
            fclose(fp);
          }

          int send_result = sendto(sockfd, eth_raw_socket_buffer_child_ack_to_host, ack_len, 0,
                           (struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll));
          if (send_result < 0)
            perror("child: sendto");
          
          printf("child: write 0x%08X to register %d\n", unit_field1, unit_field0);
        } else {
          printf("child: Invalid control field: 0x%08X, ignoring packet\n", control);
        }
        // write_le_ll_with_phdr(timestamp, access_address, header_payload_crc_len, buffer_child + runtime_len, stdout);
      } else {
        printf("child: Invalid magic header: 0x%08X, ignoring packet\n", magic_header);
      }
    }
  }

  if (fcntl(sockfd_child, F_GETFD) == -1 && errno == EBADF) {
    printf("child: socket is closed in this process already\n");
  } else {
    printf("child: socket FD is still open\n");
    close(sockfd_child);
  }
  return 0;
}

static inline int parse_mac(const char *mac_str, unsigned char mac[6]) {
  if (strlen(mac_str) < 17) return -1;  // "AA:BB:CC:DD:EE:FF"

  for (int i = 0; i < 6; i++) {
    // Each byte should be two hex chars
    if (!isxdigit(mac_str[i*3]) || !isxdigit(mac_str[i*3 + 1]))
      return -1;

    // Parse hex byte
    mac[i] = (unsigned char) strtol(&mac_str[i*3], NULL, 16);

    // Check ':' separators except after last group
    if (i < 5 && mac_str[i*3 + 2] != ':')
      return -1;
  }

  return 0;  // success
}

static inline void print_usage() {
  printf("Usage: btle_ll\n");
  printf("  -i local ethernet interface name : such as eth0\n");
  printf("  -m target MAC address of the host PC : example 01:23:45:67:89:ab (default: ff:ff:ff:ff:ff:ff)\n");
  printf("  -n channel number : such as 37. If > 78, it means frequency in Hz.\n");
  printf("  -c CRC init value : such as 0x555555\n");
  printf("  -a access address : such as 0x8E89BED6\n");
  printf("  -q IQ capture duration in seconds. Integer. Minimum 1.\n");
}

int main(int argc, char *argv[])
{
  void *map_base;
  // int fd;
  FILE *fp_rx_iq = NULL, *fp = NULL;
  char rx_iq_filename[128] = {0};
  int rx_decode_run_old = 0, i;
  int num_rx_pkt = 0, num_rx_pkt_crc_ok = 0, rx_crc_ok;
  int num_rx_pkt_hw = 0, num_rx_pkt_hw1 = 0, num_rx_pkt_hw2 = 0, num_rx_pkt_crc_ok_hw = 0;
  uint32_t rx_decode_reg_val, rx_payload_length, header_payload_crc_len, access_address_read_back;
  int itrpt_ret, n_read, iq_duration_s = -1;
  int tmp_for_irq_re_arm = 1;
  int irq_count_base = 0;
  uint64_t loop_count = 0, timestamp, timestamp_low, timestamp_high, time_current, time_old, tmp_u64, freq_hz;
  char freq_str[FREQ_HZ_STRING_BUF_SIZE];
  int irq_count_old = 0;
  uint32_t decode_end_to_host_read_counter_max = 0, reg_val, num_word, packet_word[256], start_time_s, run_time_s;
  uint32_t *rx_iq_buf;
  uint32_t num_iq_sample_total = 0, bram_addr_b = 0, read_offset = 0, num_iq_sample = 0, iq_size_in_byte_to_write = 0;
  uint32_t iq_no_loss_start_idx = 0;

  struct pollfd fds;
  pid_t pid = 1;

  unsigned long tmp;
  int opt;
  char ifname[32] = "eth0";
  // unsigned char dest_mac[6] = {0x01, 0x23, 0x45, 0x67, 0x89, 0xab};
  unsigned char dest_mac[6] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
  uint32_t channel_number = 37; // default to channel 37
  uint32_t crc_init = 0x555555; // default to 0x555555
  uint32_t unique_bit_seq = 0x8E89BED6; // default to 0x8E89BED6packet_word

  int ret = system("./fir.sh");
  if (ret == -1) {
    perror("system");
    return 1; 
  } else {
    printf("fir.sh executed successfully\n");
  }

  freq_hz = channel_number_to_freq_Hz(channel_number);

  while ((opt = getopt(argc, argv, "i:m:n:c:a:q:")) != -1) {
    switch (opt) {
      case 'i':
        strcpy(ifname, optarg);
        break;
      case 'm':
        if (parse_mac(optarg, dest_mac) != 0) {
          fprintf(stderr, "Invalid MAC address format: %s\n", optarg);
          return EXIT_FAILURE;
        }
        break;
      case 'n':
        tmp_u64 = strtoull(optarg, NULL, 10);
        channel_number = (uint32_t)tmp_u64;
        if (tmp_u64 > 78) {
          freq_hz = tmp_u64;
        } else {
          freq_hz = channel_number_to_freq_Hz(channel_number);
        }
        break;
      case 'c':
        errno = 0;
        tmp = (uint32_t)strtoul(optarg, NULL, 0);
        if (errno != 0 || tmp > 0xFFFFFFFFUL) {
          fprintf(stderr, "Invalid uint32 hex value: %s\n", optarg);
          return EXIT_FAILURE;
        }
        crc_init = (uint32_t)tmp;
        break;
      case 'a':
        errno = 0;
        tmp = (uint32_t)strtoul(optarg, NULL, 0);
        if (errno != 0 || tmp > 0xFFFFFFFFUL) {
          fprintf(stderr, "Invalid uint32 hex value: %s\n", optarg);
          return EXIT_FAILURE;
        }
        unique_bit_seq = (uint32_t)tmp;
        break;
      case 'q':
        iq_duration_s = atoi(optarg);
        break;
      default:
        print_usage();
        exit(EXIT_FAILURE);
    }
  }

  // set freq_hz to ad9361 rx0_lo
  fp = fopen(ad9361_rx0_lo_file, "w");
  if (!fp) {
    perror("fopen ad9361_rx0_lo_file");
    return -1;
  }
  freq_Hz_to_string(freq_hz, freq_str);
  if (fprintf(fp, "%s", freq_str) < 0) {
    perror("fprintf ad9361_rx0_lo_file");
    fclose(fp);
    return -1;
  }
  fclose(fp);

  num_iq_sample_total = SAMPLING_RATE_HZ * iq_duration_s;

  printf("Using interface: %s\n", ifname);
  printf("Destination MAC: %02X:%02X:%02X:%02X:%02X:%02X\n",
         dest_mac[0], dest_mac[1], dest_mac[2],
         dest_mac[3], dest_mac[4], dest_mac[5]);
  printf("Channel number: %u\n", channel_number);
  printf("Frequency: %llu\n", freq_hz);
  printf("CRC init: 0x%06X\n", crc_init);
  printf("Access address: 0x%08X\n", unique_bit_seq);
  printf("IQ duration: %ds\n", iq_duration_s);
  printf("num IQ sample total: %u\n", num_iq_sample_total);

  if (iq_duration_s == -1) {
    fd_uio = open("/dev/uio0", O_RDWR | O_SYNC);
  } else { // for IQ capture, so also mmap the axi bram
    fd_uio = open("/dev/uio1", O_RDWR | O_SYNC);
    fd_ram = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd_ram < 0) {
      perror("fd_ram open");
      return -1;
    }
    // Memory map BRAM
    map_base = mmap(NULL,
                    0x20000,
                    PROT_READ | PROT_WRITE,
                    MAP_SHARED,
                    fd_ram,
                    0x80000000);

    if (map_base == MAP_FAILED) {
        perror("fd_ram mmap");
        close(fd_ram);
        return -1;
    }

    bram_ptr = (volatile uint32_t *)map_base;

    rx_iq_buf = (uint32_t *)malloc(num_iq_sample_total*NUM_BYTES_PER_IQ_SAMPLE);
    if (rx_iq_buf == NULL) {
      perror("rx_iq_buf malloc");
      munmap((void *)map_base, 0x20000);
      close(fd_ram);
      return -1;
    }
  }

  // int fd1 = open("/dev/uio1", O_RDWR | O_SYNC);
  // struct pollfd fds[2];

  // if (fd0 < 0 || fd1 < 0) { perror("open"); return -1; }
  if (fd_uio < 0) { perror("uio open"); return -1; }

  // if (mlockall(MCL_CURRENT | MCL_FUTURE) != 0) {
  //     perror("mlockall");
  // }

  // if ((fd = open("/dev/mem", O_RDWR | O_SYNC)) == -1) {
  //   printf("/dev/mem open failed! %d\n", (int)fd);
  //   return -1;
  // }

  // fds[0].fd = fd0; fds[0].events = POLLIN;
  // fds[1].fd = fd1; fds[1].events = POLLIN;

  if (eth_raw_socket_init(ifname, dest_mac) != 0) {
    close(fd_uio);
    return -1;
  }

  // map_base = (uint32_t *)mmap(NULL, BTLE_LL_REG_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, BTLE_LL_REG_BASE);
  map_base = mmap(NULL, BTLE_LL_REG_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd_uio, 0);
  if (map_base == MAP_FAILED) {
    printf("register mmap failed! %d\n", (int)map_base);
    close(fd_uio);
    close(sockfd);
    if (iq_duration_s != -1) {
      munmap((void *)bram_ptr, BRAM_SIZE);
      close(fd_ram);
      free(rx_iq_buf);
    }
    return -1;
  }
  fpga_regs = (volatile uint32_t *)map_base;

  signal(SIGINT, handle_sigint);
  signal(SIGTERM, handle_sigint);

  if (write(fd_uio, &tmp_for_irq_re_arm, sizeof(tmp_for_irq_re_arm)) != sizeof(tmp_for_irq_re_arm)) {
    perror("write");
    close(fd_uio);
    munmap((void *)map_base, BTLE_LL_REG_SIZE);
    close(sockfd);
    if (iq_duration_s != -1) {
      munmap((void *)bram_ptr, BRAM_SIZE);
      close(fd_ram);
      free(rx_iq_buf);
    }
    return -1;
  }

  fpga_regs[0] = (1<<15); // reset hardware counter
  __sync_synchronize();
  usleep(100);

  // btle_ll_base_p[BTLE_LL_REG_RX_UNIQUE_BIT_SEQ_IDX] = 0xD6BE898E;
  fpga_regs[BTLE_LL_REG_RX_CHANNEL_NUMBER_IDX] = channel_number;
  fpga_regs[BTLE_LL_REG_RX_CRC_INIT_BIT_IDX] = crc_init;
  fpga_regs[BTLE_LL_REG_RX_PDU_MEM_ADDR_IDX] = 0;
  fpga_regs[BTLE_LL_REG_RX_UNIQUE_BIT_SEQ_IDX] = unique_bit_seq; // this is the right setting!

  __sync_synchronize();
  fpga_regs[0] = 0;

  fds = (struct pollfd){ .fd = fd_uio, .events = POLLIN };

  start_time_s = get_time_s();

  if (iq_duration_s == -1) {
    pid = fork();
    if (pid < 0) {
        perror("fork");
        close(fd_uio);
        munmap((void *)map_base, BTLE_LL_REG_SIZE);
        close(sockfd);
        if (iq_duration_s != -1) {
          munmap((void *)bram_ptr, BRAM_SIZE);
          close(fd_ram);
          free(rx_iq_buf);
        }
        return 1;
    }
  }

  if (pid == 0) {
    if (prctl(PR_SET_PDEATHSIG, SIGTERM) == -1) {
      perror("child: prctl");
      // continue anyway
    }
    // Optional extra safety: if parent already died before prctl was set:
    if (getppid() == 1) {
      // parent is gone, exit
      fprintf(stderr, "child: parent already dead, exiting\n");
      _exit(1);
    }

    pin_to_cpu(0);            // Bind to CPU0
    set_realtime_priority();  // RT scheduling

    signal(SIGTERM, handle_sigint_child);  // optional cleanup
    signal(SIGINT, handle_sigint_child);   // optional cleanup

    // run the function
    host_intf();

    _exit(0);
  } else {
    // usleep(4000000); // wait for the other process to init
    pin_to_cpu(1);            // Bind to CPU1
    set_realtime_priority();  // RT scheduling
    
    if (set_irq_affinity(56, "2") == 0) {
      DEBUG_PRINT(printf("IRQ %d affinity set to mask %s\n", 56, "2");)
    } else {
      printf("Failed to set IRQ affinity 56\n");
      // close(fd_uio0);
      // return -1;
    }

    if (set_irq_affinity(57, "2") == 0) {
      DEBUG_PRINT(printf("IRQ %d affinity set to mask %s\n", 57, "2");)
    } else {
      printf("Failed to set IRQ affinity 57\n");
      // close(fd_uio0);
      // return -1;
    }

    for (i = 33; i<= 38; i++) {
      if (set_irq_affinity(i, "1") == 0) {
        DEBUG_PRINT(printf("IRQ %d affinity set to mask %s\n", i, "1");)
      } else {
        printf("Failed to set IRQ affinity\n");
        // close(fd_uio0);
        // return -1;
      }
    }

    time_old = get_time_us();
    while (!signal_stop) {
      fpga_regs[0] = 0;
      // Main loop code
      // if ( (rx_decode_reg_val&(1<<18)) != 0 && rx_decode_run_old == 0) {
      // itrpt_ret = poll(fds, 2, -1);
      // if (itrpt_ret < 0) { perror("poll"); break; }
      // if (fds[0].revents & POLLIN) 

      // __sync_synchronize();
      poll(&fds, 1, -1);
      __sync_synchronize();

      n_read = read(fd_uio, &irq_count, sizeof(irq_count));
      if (n_read != sizeof(irq_count)) {
        perror("read");
        break;
      }
      __sync_synchronize();

      // --- Acknowledge / re-enable the interrupt ---
      if (write(fd_uio, &tmp_for_irq_re_arm, sizeof(tmp_for_irq_re_arm)) != sizeof(tmp_for_irq_re_arm)) {
        perror("write");
      }

      if (iq_duration_s == -1) {
        fpga_regs[39] = 1;

        rx_decode_reg_val = fpga_regs[49];
        rx_crc_ok = ((rx_decode_reg_val>>16)&0x01);
        rx_payload_length = ((rx_decode_reg_val>>8)&0xFF);
        header_payload_crc_len = 2 + rx_payload_length + 3; // add 2 bytes header, 3 bytes CRC
        num_word = (header_payload_crc_len >> 2) + ((header_payload_crc_len & 3) ? 1 : 0);
        for (i = 0; i < num_word; i++) {
          packet_word[i] = fpga_regs[40];
        }

        if ( (rx_decode_reg_val&(1<<16)) != 0) {
          num_rx_pkt_crc_ok++;
        }

        __sync_synchronize();
        fpga_regs[40] = 0;

        // timestamp resolution: 1/bb_clk = 1/16 us = 62.5 ns
        timestamp_low = fpga_regs[56];
        timestamp_high = fpga_regs[57];

        if (rx_crc_ok) // carry rx crc ok flag into MSB of timestamp_high
          timestamp_high = (timestamp_high | (1<<31));
        else
          timestamp_high = (timestamp_high & ~(1<<31));

        access_address_read_back = fpga_regs[BTLE_LL_REG_RX_UNIQUE_BIT_SEQ_IDX];
        num_rx_pkt_hw = fpga_regs[50];
        num_rx_pkt_hw2 = fpga_regs[53];
        num_rx_pkt_hw1 = fpga_regs[55];
        if ( num_rx_pkt_hw != num_rx_pkt_hw1 || num_rx_pkt_hw2 != num_rx_pkt_hw1) {
          DEBUG_PRINT(printf("num rx pkt hw %d %d %d\n", num_rx_pkt_hw, num_rx_pkt_hw1, num_rx_pkt_hw2);)
          __sync_synchronize();
          // break;
        }

        reg_val = fpga_regs[41];
        if (reg_val > decode_end_to_host_read_counter_max) {
          decode_end_to_host_read_counter_max = reg_val;
          DEBUG_PRINT(printf("max latency %d time %ds\n", decode_end_to_host_read_counter_max, get_time_s() - start_time_s);)
        }

        num_rx_pkt_crc_ok_hw = fpga_regs[51];
        __sync_synchronize();

        timestamp = ((timestamp_high << 32) | timestamp_low);
        if (eth_raw_socket_send(timestamp, access_address_read_back, header_payload_crc_len, (char *)packet_word, num_word<<2) < 0) {
          break;
        }
        fpga_regs[39] = 0;
      } else { //save iq to memory and write to file when num iq reach num_iq_sample_total
        bram_addr_b = fpga_regs[59];
        __sync_synchronize();
        read_offset = (bram_addr_b < BRAM_SIZE_IN_WORD_HALF? BRAM_SIZE_IN_WORD_HALF : 0);
        iq_size_in_byte_to_write = (num_iq_sample_total - num_iq_sample);
        if (iq_size_in_byte_to_write < BRAM_SIZE_IN_WORD_HALF) {
          iq_size_in_byte_to_write = iq_size_in_byte_to_write * NUM_BYTES_PER_IQ_SAMPLE;
        } else {
          iq_size_in_byte_to_write = BRAM_SIZE_HALF;
        }
        memcpy(rx_iq_buf + num_iq_sample, (void *)(bram_ptr + read_offset), iq_size_in_byte_to_write);
        __sync_synchronize();
        
        bram_addr_b = fpga_regs[59];
        __sync_synchronize();

        num_iq_sample += (iq_size_in_byte_to_write / NUM_BYTES_PER_IQ_SAMPLE);
        if ( (read_offset == 0 && bram_addr_b < BRAM_SIZE_IN_WORD_HALF) || (read_offset == BRAM_SIZE_IN_WORD_HALF && bram_addr_b >= BRAM_SIZE_IN_WORD_HALF) ) {
          printf("Loss. num sample %u r offset %u new addr %u\n", num_iq_sample, read_offset, bram_addr_b);
          iq_no_loss_start_idx = num_iq_sample;
        }

        if (num_iq_sample == num_iq_sample_total) {
          break;
        }
      }
      
      if (loop_count == 0) {
        irq_count_base = irq_count;
        irq_count_old = irq_count - 1;
      }
      loop_count++;

      if (irq_count != irq_count_old + 1) {
        printf("Missed IRQ! irq_count = %u, old = %u\n", irq_count, irq_count_old);
        // break;
      }
      irq_count_old = irq_count;

      // printf("Interrupt received! irq_count = %u\n", irq_count);

      num_rx_pkt++;
      // __sync_synchronize();
      // if (num_rx_pkt != num_rx_pkt_hw) {
      //   fpga_regs[0] = 1;
      //   __sync_synchronize();
      //   break;
      // }

      // printf("%d %d\n", num_rx_pkt, irq_count);
      if ( (irq_count - irq_count_base + 1) != num_rx_pkt) {
        fpga_regs[0] = 1;
        printf("%d %d %d\n", irq_count, irq_count_base, num_rx_pkt);
        __sync_synchronize();
        // break;
      }

      __sync_synchronize();
      
      if (0) {
      time_current = get_time_us();
      tmp_u64 = time_current - time_old;
      if (tmp_u64 < 1500)
        fpga_regs[0] = 1;

      time_old = time_current;

      printf("%llu %llu\n", loop_count, tmp_u64);
      }

      // printf("Payload length: %d, Data: ",  rx_payload_length);
      // for (i = 0; i < num_word; i++) {
      //   printf("%08X ", packet_word[i]);
      // }
      // printf("\n");

      // break;

      // fpga_regs[0] = 1;
      // fpga_regs[0] = 0;
      // }
      // rx_decode_run_old = (rx_decode_reg_val&(1<<18));
    }

    DEBUG_PRINT(printf("payload len %d pkt total %d crc ok %d hw pkt total %d total1 %d crc ok %d\n", rx_payload_length, num_rx_pkt, num_rx_pkt_crc_ok, num_rx_pkt_hw, num_rx_pkt_hw1, num_rx_pkt_crc_ok_hw);)

    munmap((void *)map_base, BTLE_LL_REG_SIZE);
    // close(fd);
    close(fd_uio);
    // close(fd1);

    close(sockfd);

    if (iq_duration_s != -1) {
      num_iq_sample = num_iq_sample_total - iq_no_loss_start_idx;
      printf("IQ capture to memory done. Valid num IQ samples (no loss): %u\n", num_iq_sample);

      sprintf(rx_iq_filename, "rx_iq_%lluHz_%usps_num%u.bin", freq_hz, SAMPLING_RATE_HZ, num_iq_sample);
      fp_rx_iq = fopen(rx_iq_filename, "wb");
      if (fp_rx_iq == NULL) {
        perror("fp_rx_iq Failed to open file");
      } else {
        i = fwrite(rx_iq_buf+iq_no_loss_start_idx, NUM_BYTES_PER_IQ_SAMPLE, num_iq_sample, fp_rx_iq);
        if (i != num_iq_sample) {
          printf("Incomplete write operation on fp_rx_iq. %d vs %d\n", i, num_iq_sample);
        }
        printf("Saved %u IQ samples to file %s\n", num_iq_sample, rx_iq_filename);
      }

      munmap((void *)bram_ptr, BRAM_SIZE);
      close(fd_ram);
      free(rx_iq_buf);
      if (fp_rx_iq != NULL)
        fclose(fp_rx_iq);
    }

    if (iq_duration_s == -1) {
      // Optionally tell the child to exit gracefully, then wait
      // Example: send SIGTERM
      kill(pid, SIGTERM);
      waitpid(pid, NULL, 0);
      printf("parent: child terminated, exiting\n");
    }
  }

  return(0);
}
