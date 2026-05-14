// btle_json.h
// NDJSON event emitter for btle_rx. Opt-in via --json flag.
// Each emit writes one JSON object + newline to stdout and fflushes.
//
// ---------- Schema v1 ----------
// Every line: {"v":1,"t":<type>,"ts":<float_seconds>,...}
//
// t:"pkt" (adv branch):
//   {"v":1,"t":"pkt","ts":1715680000.123456,"pkt":42,"ch":37,
//    "aa":"8e89bed6","crc_ok":true,"kind":"adv","pdu_type":0,
//    "pdu_name":"ADV_IND","tx_add":1,"rx_add":0,"plen":31,
//    "adv_a":"aa:bb:cc:dd:ee:ff",
//    "payload_hex":"02011a0aff4c00...","rssi_est":-58}
//
// t:"pkt" (data branch, AdvA absent):
//   {"v":1,"t":"pkt","ts":...,"pkt":...,"ch":12,"aa":"60850a1b",
//    "crc_ok":true,"kind":"data","ll_pdu_type":1,"ll_pdu_name":"LL_DATA",
//    "nesn":0,"sn":1,"md":0,"plen":4,"payload_hex":"03000000",
//    "rssi_est":null}
//
// t:"hop":
//   {"v":1,"t":"hop","ts":...,"event":"track_start"|"chan_change"|"track_drop",
//    "state_from":0,"state_to":1,"ch":7,"freq_mhz":2410,"aa":"60850a1b",
//    "crc_init":"a77b22","interval_us":18750,"hop":5,"chm":"1fffffffff"}
//
// t:"status":
//   {"v":1,"t":"status","ts":...,
//    "event":"start"|"stop"|"error","board":"HackRF","ch":37,
//    "freq_hz":2402000000,"gain":40,"lna":32,"amp":0,
//    "filter_adva":"...","msg":"..."}

#ifndef BTLE_JSON_H
#define BTLE_JSON_H

#include <stdint.h>
#include <sys/time.h>

#ifdef __cplusplus
extern "C" {
#endif

// Enable/disable JSON emission globally. When disabled all emit_* are no-ops.
void btj_init(int enabled);
int  btj_enabled(void);

// One ADV-branch packet event.
// adv_a may be NULL when AdvA isn't available for this PDU type (e.g. type 7+).
// rssi_dbm = INT_MIN means "null" in the JSON output (no estimate).
void btj_emit_pkt_adv(const struct timeval *ts,
                      int pkt_count,
                      int channel,
                      uint32_t access_addr,
                      int crc_ok,
                      int pdu_type,
                      const char *pdu_name,
                      int tx_add,
                      int rx_add,
                      int payload_len,
                      const uint8_t *adv_a,         // 6 bytes, may be NULL
                      const uint8_t *payload_bytes, // payload_len bytes
                      int rssi_dbm);

// One DATA-channel packet event.
void btj_emit_pkt_data(const struct timeval *ts,
                       int pkt_count,
                       int channel,
                       uint32_t access_addr,
                       int crc_ok,
                       int ll_pdu_type,
                       const char *ll_pdu_name,
                       int nesn,
                       int sn,
                       int md,
                       int payload_len,
                       const uint8_t *payload_bytes,
                       int rssi_dbm);

// One hop FSM transition.
// event: "track_start" | "chan_change" | "track_drop"
// chm is 5 bytes; aa, crc_init, interval_us, hop, freq_mhz may be omitted by
// passing zeros AND a NULL chm — but typical callers fill everything.
void btj_emit_hop(const struct timeval *ts,
                  const char *event,
                  int state_from,
                  int state_to,
                  int channel,
                  uint64_t freq_mhz,
                  uint32_t aa,
                  uint32_t crc_init,
                  int interval_us,
                  int hop_increment,
                  const uint8_t *chm /* 5 bytes, may be NULL */);

// Status events for lifecycle / errors.
// filter_adva may be NULL (means no filter active).
void btj_emit_status(const struct timeval *ts,
                     const char *event,
                     const char *board,
                     int channel,
                     uint64_t freq_hz,
                     int gain,
                     int lna,
                     int amp,
                     const uint8_t *filter_adva /* 6 bytes, may be NULL */,
                     const char *msg /* may be NULL */);

#ifdef __cplusplus
}
#endif

#endif // BTLE_JSON_H
