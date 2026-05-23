#ifndef BOOT_INFO_H
#define BOOT_INFO_H

#include <stdint.h>

#define BOOT_INFO_ADDR 0x00009000UL
#define BOOT_INFO_MAGIC 0x304D554CUL

struct boot_info {
    uint32_t magic;
    uint8_t version;
    uint8_t boot_drive;
    uint16_t conventional_kb;
    uint16_t extended_kb;
    uint32_t total_kb;
    uint16_t root_dir_entries;
    uint32_t root_dir_addr;
    uint32_t file_table_addr;
    uint32_t file_count;
    uint32_t fb_addr;
    uint32_t fb_width;
    uint32_t fb_height;
    uint32_t fb_pitch;
    uint8_t fb_bpp;
    uint8_t fb_red_pos;
    uint8_t fb_green_pos;
    uint8_t fb_blue_pos;
} __attribute__((packed));

static inline volatile struct boot_info *boot_info_get(void) {
    return (volatile struct boot_info *)BOOT_INFO_ADDR;
}

#endif
