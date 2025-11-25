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

// #define DEBUG_PRINT(...) printf(__VA_ARGS__)
#define DEBUG_PRINT(...)

int sockfd = 0;
struct sockaddr_ll socket_address;
unsigned char eth_raw_socket_buffer[1500];

volatile sig_atomic_t signal_stop = 0;  // flag set by signal handler

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

static inline void handle_sigint(int sig) {
  signal_stop = 1;  // just set the flag, keep it simple & async-signal-safe

  // if (write(fd_uio0, &tmp_for_irq_re_arm, sizeof(tmp_for_irq_re_arm)) != sizeof(tmp_for_irq_re_arm)) {
  //   perror("write");
  // }

  printf("Quitting...\n");
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

  // // 5. Add payload (your binary data)
  // const char payload[] = "HelloBinary";
  // int payload_len = sizeof(payload);
  // memcpy(eth_raw_socket_buffer + sizeof(struct ether_header), payload, payload_len);

  // 6. Prepare sockaddr_ll
  memset(&socket_address, 0, sizeof(struct sockaddr_ll));
  socket_address.sll_ifindex = if_idx.ifr_ifindex;
  socket_address.sll_halen = ETH_ALEN;
  memcpy(socket_address.sll_addr, dest_mac, 6);

  return 0;
}

static inline int eth_raw_socket_send(uint32_t num_byte, uint8_t *packet_byte) {
  // Copy payload after Ethernet header
  memcpy(eth_raw_socket_buffer + sizeof(struct ether_header), packet_byte, num_byte);

  // Send the packet
  int frame_len = sizeof(struct ether_header) + num_byte;
  int send_result = sendto(sockfd, eth_raw_socket_buffer, frame_len, 0,
                           (struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll));
  if (send_result < 0)
    perror("sendto");

  return send_result;
}

int parse_mac(const char *mac_str, unsigned char mac[6]) {
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
  printf("  -m target MAC address of the SDR device : example 01:23:45:67:89:ab (default: ff:ff:ff:ff:ff:ff)\n");
  printf("  -n channel number : such as 37\n");
  printf("  -c CRC init value : such as 0x555555\n");
  printf("  -a access address : such as 0x8E89BED6\n");
}

int main(int argc, char *argv[])
{
  unsigned long tmp;
  int opt;

  char ifname[32] = "eno1";
  // unsigned char dest_mac[6] = {0x01, 0x23, 0x45, 0x67, 0x89, 0xab};
  unsigned char dest_mac[6] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
  uint32_t channel_number = 37; // default to channel 37
  uint32_t crc_init = 0x555555; // default to 0x555555
  uint32_t unique_bit_seq = 0x8E89BED6; // default to 0x8E89BED6

  const uint32_t magic_header_len = 4;
  const uint32_t timestamp_len = 8;
  const uint32_t control_len = 4;
  const uint32_t unit_field_len = 4;

  uint8_t packet_byte[64] = {0,1,2,3,4,5,6};
  uint32_t num_byte = magic_header_len + timestamp_len + control_len + 2*unit_field_len;
  uint32_t runtime_len;

  while ((opt = getopt(argc, argv, "i:m:n:c:a:")) != -1) {
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
        channel_number = atoi(optarg);
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
      default:
        print_usage();
        exit(EXIT_FAILURE);
    }
  }
  printf("Using interface: %s\n", ifname);
  printf("Destination MAC: %02X:%02X:%02X:%02X:%02X:%02X\n",
         dest_mac[0], dest_mac[1], dest_mac[2],
         dest_mac[3], dest_mac[4], dest_mac[5]);
  printf("Channel number: %u\n", channel_number);
  printf("CRC init: 0x%06X\n", crc_init);
  printf("Access address: 0x%08X\n", unique_bit_seq);

  pin_to_cpu(1);            // Bind to CPU1
  set_realtime_priority();  // RT scheduling
  
  // if (set_irq_affinity(56, "2") == 0) {
  //   DEBUG_PRINT(printf("IRQ %d affinity set to mask %s\n", 56, "2");)
  // } else {
  //   printf("Failed to set IRQ affinity\n");
  //   close(fd_uio0);
  //   return -1;
  // }

  // for (i = 34; i<= 37; i++) {
  //   if (set_irq_affinity(i, "1") == 0) {
  //     DEBUG_PRINT(printf("IRQ %d affinity set to mask %s\n", i, "1");)
  //   } else {
  //     printf("Failed to set IRQ affinity\n");
  //     close(fd_uio0);
  //     return -1;
  //   }
  // }

  if (eth_raw_socket_init(ifname, dest_mac) != 0) {
    return -1;
  }

  signal(SIGINT, handle_sigint);
  signal(SIGTERM, handle_sigint);

  __sync_synchronize();

  while (!signal_stop) {
    runtime_len = 0;
    // 4 bytes magic header
    ((uint32_t*)(packet_byte + runtime_len))[0] = 0x64838364;

    runtime_len = runtime_len + magic_header_len;
    // 8 bytes timestamp
    ((uint64_t*)(packet_byte + runtime_len))[0] = get_time_us();

    runtime_len = runtime_len + timestamp_len;
    // 4 bytes control
    ((uint32_t*)(packet_byte + runtime_len))[0] = 0;

    runtime_len = runtime_len + control_len;
    // 4 bytes unit_field0
    ((uint32_t*)(packet_byte + runtime_len))[0] = 11; // register index
    runtime_len = runtime_len + unit_field_len;
    // 4 bytes unit_field1
    ((uint32_t*)(packet_byte + runtime_len))[0] = 37;

    num_byte = runtime_len + unit_field_len;
    if (eth_raw_socket_send(num_byte, packet_byte) < 0) {
      break;
    }
    printf("cmd sent at (us) %llu\n", (unsigned long long)get_time_us());
    break;
  }

  DEBUG_PRINT(printf("num_byte %d\n", num_byte);)

  close(sockfd);

  return(0);
}
