#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>   

typedef struct __attribute__((packed))
{
    uint8_t BootjumpInstruction[3];
    uint8_t OemIndentifier[8];
    uint16_t BytesPerSector;
    uint8_t SectorsPerCluster;
    uint16_t ReservedSectors;
    uint8_t FatCount;
    uint16_t DirEntryCount;
    uint16_t TotalSectors;
    uint8_t MediaDescriptorType;
    uint16_t SectorsPerFat;
    uint16_t SectorsPerTrack;
    uint16_t Heads;
    uint32_t HiddenSectors;
    uint32_t LargerSectorCount;

    uint8_t Drive_number;
    uint8_t _Reserved;
    uint8_t Signature;
    uint32_t VolumeID;
    uint8_t VolumeLabel[11];
    uint8_t SystemId[8];
} BootSector;

BootSector g_BootSector;
uint8_t* g_Fat = NULL;

bool readBootSector(FILE* disk)
{
    return fread(&g_BootSector, sizeof(g_BootSector), 1, disk) > 0;
}

bool readSectors(FILE* disk, uint32_t lba, uint32_t count, void* bufferOut)
{
    bool ok = true;
    ok = ok && (fseek(disk, lba * g_BootSector.BytesPerSector, SEEK_SET) == 0);
    ok = ok && (fread(bufferOut, g_BootSector.BytesPerSector, count, disk) == count);
    return ok;
}

bool readFat(FILE* disk)
{
    size_t fatSize = g_BootSector.SectorsPerFat * g_BootSector.BytesPerSector;
    g_Fat = (uint8_t*) malloc(fatSize);
    if (!g_Fat) {
        fprintf(stderr, "Memory allocation failed for FAT\n");
        return false;
    }
    return readSectors(disk, g_BootSector.ReservedSectors, g_BootSector.SectorsPerFat, g_Fat);
}

int main(int argc, char** argv)
{
    if (argc < 3) {
        printf("Syntax: %s <disk image> <file image>\n", argv[0]);
        return -1;
    }

    FILE* disk = fopen(argv[1], "rb");
    if (!disk) {
        fprintf(stderr, "Cannot open disk image %s!\n", argv[1]);
        return -1;
    }

    if (!readBootSector(disk)) {
        fprintf(stderr, "Could not read boot sector!\n");
        fclose(disk);
        return -2;
    }

    if (!readFat(disk)) {
        fprintf(stderr, "Could not read FAT!\n");
        fclose(disk);
        free(g_Fat);
        return -3;
    }

    printf("Boot sector read successfully!\n");
    printf("Bytes per sector: %u\n", g_BootSector.BytesPerSector);
    printf("Sectors per cluster: %u\n", g_BootSector.SectorsPerCluster);
    printf("FAT size: %u sectors\n", g_BootSector.SectorsPerFat);

    fclose(disk);
    free(g_Fat);
    return 0;
}
