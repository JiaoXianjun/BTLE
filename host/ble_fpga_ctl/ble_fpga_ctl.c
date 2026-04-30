// Author: Xianjun Jiao <putaoshu@msn.com>
// SPDX-FileCopyrightText: 2025 Xianjun Jiao
// SPDX-License-Identifier: Apache-2.0 license

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/ether.h>
#include <netpacket/packet.h>
#include <net/if.h>
#include <sys/ioctl.h>
#include <arpa/inet.h>
#include <stdint.h>
#include <time.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <errno.h>
#include <fcntl.h>

#define DLT_BLUETOOTH_LE_LL_WITH_PHDR 256
#define DLT_BLUETOOTH_LE_LL 251

struct __attribute__((__packed__)) pcap_hdr {
  uint32_t magic_number;
  uint16_t version_major;
  uint16_t version_minor;
  int32_t  thiszone;
  uint32_t sigfigs;
  uint32_t snaplen;
  uint32_t network;
};

struct __attribute__((__packed__)) pcaprec_hdr {
  uint32_t ts_sec;
  uint32_t ts_usec;
  uint32_t incl_len;
  uint32_t orig_len;
};

// ----------------------------- BLE PHY Header -----------------------------
struct __attribute__((__packed__)) ble_ll_phdr {
  uint8_t  channel;        // 0-39
  int8_t   signal_power;   // RSSI (dBm)
  int8_t   noise_power;    // dBm
  int8_t   access_address_offenses;
  uint8_t  access_address[4]; // little-endian
  uint16_t  flags;          // bitfield: 0x01=advertising channel
};

// ----------------------------- PCAP Output Helpers -----------------------------
// static inline void write_pcap_header(FILE *f) {
static inline void write_pcap_header(void) {
  struct __attribute__((__packed__)) pcap_hdr hdr = {
    .magic_number = 0xa1b2c3d4,
    .version_major = 2,
    .version_minor = 4,
    .thiszone = 0,
    .sigfigs = 0,
    .snaplen = 65535,
    // .network = DLT_BLUETOOTH_LE_LL_WITH_PHDR
    .network = DLT_BLUETOOTH_LE_LL
  };
  // fwrite(&hdr, sizeof(hdr), 1, f);
  // fflush(f);
  int tmp = write(1, &hdr, sizeof(hdr));
}

// timestamp resolution: 1/bb_clk = 1/16 us = 62.5 ns
// static inline void write_le_ll_with_phdr(uint64_t timestamp, uint32_t access_address, uint32_t header_payload_crc_len, char *packet_byte, FILE *f) {
static inline void write_le_ll_with_phdr(uint64_t timestamp, uint32_t access_address, uint32_t header_payload_crc_len, char *packet_byte) {
  // uint32_t total_len = sizeof(phdr) + payload_length + 4;
  // struct __attribute__((__packed__)) ble_ll_phdr phdr = {
  //   .channel = 37,
  //   .signal_power = -45,
  //   .noise_power = -90,
  //   .access_address_offenses = 0,
  //   .access_address = {0xD6, 0xBE, 0x89, 0x8E}, // 0x8E89BED6 (advertising AA)
  //   .flags = 0x0001 // advertising channel
  // };

  uint64_t timestamp_us = (timestamp >> 4); // convert to microseconds
  uint64_t timestamp_s =  (timestamp_us / 1000000);
  
  uint32_t total_len = header_payload_crc_len + sizeof(access_address);

  // struct timespec ts;
  // clock_gettime(CLOCK_REALTIME, &ts);
  timestamp_us = (timestamp_us -  timestamp_s * 1000000);

  struct __attribute__((__packed__)) pcaprec_hdr rec = {
    // .ts_sec  = ts.tv_sec,
    // .ts_usec = ts.tv_nsec / 1000,
    .ts_sec  = timestamp_s,
    .ts_usec = timestamp_us,
    .incl_len = total_len,
    .orig_len = total_len
  };

  // fwrite(&rec, sizeof(rec), 1, f);
  // // fwrite(&phdr, sizeof(phdr), 1, f);
  // fwrite(&access_address, 4, 1, f);
  // fwrite(packet_byte, header_payload_crc_len, 1, f);
  // fflush(f);

  int tmp = write(1, &rec, sizeof(rec));
  tmp = write(1, &access_address, 4);
  tmp = write(1, packet_byte, header_payload_crc_len);
}

static inline uint64_t get_time_us() {
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts); // Monotonic: not affected by system clock changes
  return (uint64_t)ts.tv_sec * 1000000ULL + ts.tv_nsec / 1000;
}

int main() {
  int sockfd;
  uint8_t buffer[1536];
  const char *ifname = "eno1";
  const unsigned short ether_type = 0x88B5;
  const uint32_t eth_header_len = sizeof(struct ether_header);
  const uint32_t magic_header_len = 4;
  const uint32_t timestamp_len = 8;
  const uint32_t access_address_len = 4;
  const uint32_t length_field_len = 4;
  uint32_t runtime_len = 0, magic_header, header_payload_crc_len, access_address;
  uint64_t timestamp, rx_crc_ok;
  uint32_t total_len = eth_header_len + magic_header_len + timestamp_len + access_address_len + length_field_len;
  uint32_t total_len_magic_header = eth_header_len + magic_header_len;
  uint32_t num_crc_err_pkt = 0, num_crc_ok_pkt = 0, num_pkt_total = 0;

  sockfd = socket(AF_PACKET, SOCK_RAW, htons(ether_type));
  if (sockfd < 0) { perror("socket"); return 1; }

  struct ifreq ifr;
  memset(&ifr, 0, sizeof(ifr));
  strncpy(ifr.ifr_name, ifname, IFNAMSIZ - 1);
  ioctl(sockfd, SIOCGIFINDEX, &ifr);

  struct sockaddr_ll saddr = {0};
  saddr.sll_family = AF_PACKET;
  saddr.sll_protocol = htons(ether_type);
  saddr.sll_ifindex = ifr.ifr_ifindex;

  if (bind(sockfd, (struct sockaddr*)&saddr, sizeof(saddr)) < 0) {
    perror("bind");
    close(sockfd);
    return 1;
  }

  // if (chmod("/tmp/blepipe", 0666) < 0) {
  //   perror("chmod fifo");
  // }

  // int fd = open("/tmp/blepipe", O_WRONLY | O_NONBLOCK);
  // if (fd < 0) {
  //     perror("open fifo");
  //     fprintf(stderr, "Cannot open %s for writing: %s\n", "/tmp/blepipe", strerror(errno));
  //     return 1;
  // }
  
  // FILE *f = fopen(fd, "wb");
  // if (!f) {
  //   perror("open pipe");
  //   close(sockfd);
  //   return 1;
  // }

  // write_pcap_header(stdout);
  write_pcap_header();
  while (1) {
    ssize_t numbytes = recvfrom(sockfd, buffer, sizeof(buffer), 0, NULL, NULL);
    if (numbytes > 0) {
      // printf("Received %zd bytes: ", numbytes);
      // for (int i = sizeof(struct ether_header); i < numbytes; i++)
      //     printf("%02x ", buffer[i]);
      // printf("\n");

      if (numbytes < total_len_magic_header) {
        fprintf(stderr, "Packet too short (%zd bytes < %u bytes) for magic header, ignoring\n", numbytes, total_len_magic_header);
        continue;
      }

      runtime_len = eth_header_len;
      // 4 bytes magic header
      magic_header = ((uint32_t*)(buffer + runtime_len))[0];

      if (magic_header == 0x05628562) {
        if (numbytes < total_len) {
          fprintf(stderr, "Packet too short (%zd bytes < %u bytes), ignoring\n", numbytes, total_len);
          continue;
        }

        runtime_len = runtime_len + magic_header_len;
        // 8 bytes timestamp
        timestamp = ((uint64_t*)(buffer + runtime_len))[0];

        rx_crc_ok = (timestamp&0x8000000000000000ULL);
        if (rx_crc_ok) { // only show CRC OK packets in wireshark
          // fprintf(stderr, "Warning: timestamp upper 16 bits are not zero: 0x%016llX\n", (unsigned long long)(timestamp));
          // num_crc_ok_pkt++;
          runtime_len = runtime_len + timestamp_len;
          // 4 bytes access_address
          access_address = ((uint32_t*)(buffer + runtime_len))[0];

          runtime_len = runtime_len + access_address_len;
          // 4 bytes header_payload_crc_len
          header_payload_crc_len = ((uint32_t*)(buffer + runtime_len))[0];

          runtime_len = runtime_len + length_field_len;

          // write_le_ll_with_phdr(timestamp, access_address, header_payload_crc_len, buffer + runtime_len, stdout);
          write_le_ll_with_phdr(timestamp&(~0x8000000000000000ULL), access_address, header_payload_crc_len, buffer + runtime_len);
          // fprintf(stderr, "1\n");
        } else {
          num_crc_err_pkt++;
        }
        num_pkt_total++;
        if (num_crc_err_pkt == 100) {
          fprintf(stderr, "CRC err/total %d/%d %f\n", num_crc_err_pkt, num_pkt_total, (float)num_crc_err_pkt / num_pkt_total);
          num_crc_err_pkt = 0;
          num_pkt_total = 0;
        }
      } else if (magic_header == 0x19293811) {
        timestamp = get_time_us();
        fprintf(stderr, "ACK packet received at (us) %llu\n", (unsigned long long)timestamp);
      } else {
        fprintf(stderr, "Invalid magic header: 0x%08X, ignoring packet\n", magic_header); 
      }
    }
  }
  // fclose(f);
  close(sockfd);
  return 0;
}
