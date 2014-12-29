#ifndef JOS_KERN_E1000_H
#define JOS_KERN_E1000_H

#include <inc/string.h>
#include <kern/pci.h>
#include <kern/pmap.h>
/* Taken from http://www3.cs.stonybrook.edu/~porter/courses/cse506/f14/e1000_hw.h */

/* PCI Device IDs ---- QEMU emulates the 82540EM */

#define PCI_VEN_ID 			   0x8086
#define PCI_DEV_ID		       0x100e

#define PCI_TXDESC		   	   64
#define TX_PKT_SIZE            1518
#define PCI_RXDESC             64
#define RX_PKT_SIZE            2048

/* Register Set. (82543, 82544)
 *
 * Registers are defined to be 32 bits and  should be accessed as 32 bit values.
 * These registers are physically located on the NIC, but are mapped into the
 * host memory address space.
 *
 * RW - register is both readable and writable
 * RO - register is read only
 * WO - register is write only
 * R/clr - register is read only and is cleared when read
 * A - register array
 * Register set stolen from 
 */

#define E1000_TDBAL    0x03800/4  /* TX Descriptor Base Address Low - RW */
#define E1000_TDBAH    0x03804/4  /* TX Descriptor Base Address High - RW */
#define E1000_TDLEN    0x03808/4  /* TX Descriptor Length - RW */
#define E1000_TDH      0x03810/4  /* TX Descriptor Head - RW */
#define E1000_TDT      0x03818/4  /* TX Descripotr Tail - RW */

#define E1000_STATUS     0x00008/4  /* Device Status - RO */
#define E1000_EERD       0x00014/4  /* EEPROM Read - RW */
#define E1000_EERD_START 0x01
#define E1000_EERD_DONE  0x10

#define E1000_RDBAL    0x02800/4  /* RX Descriptor Base Address Low - RW */
#define E1000_RDBAH    0x02804/4  /* RX Descriptor Base Address High - RW */
#define E1000_RDLEN    0x02808/4  /* RX Descriptor Length - RW */
#define E1000_RDH      0x02810/4  /* RX Descriptor Head - RW */
#define E1000_RDT      0x02818/4  /* RX Descriptor Tail - RW */
#define E1000_RAL      0x05400/4  /* Receive Address Low - RW */
#define E1000_RAH      0x05404/4  /* Receive Address High - RW */
#define E1000_RAH_AV   0x80000000        /* Receive descriptor valid */
#define E1000_MTA      0x05200/4  /* Multicast Table Array - RW Array */

#define E1000_TCTL     	  0x00400/4  /* TX Control - RW */
#define E1000_TCTL_EN     0x00000002    /* enable tx */
#define E1000_TCTL_PSP    0x00000008    /* pad short packets */
#define E1000_TCTL_CT     0x00000ff0    /* collision threshold */
#define E1000_TCTL_COLD   0x003ff000    /* collision distance */

#define E1000_RCTL     			  0x00100/4  /* RX Control - RW */
#define E1000_RCTL_EN             0x00000002    /* enable */
#define E1000_RCTL_LPE            0x00000020    /* long packet enable */
#define E1000_RCTL_LBM            0x000000C0    /* loopback mode */
#define E1000_RCTL_RDMTS          0x00000300    /* rx min threshold size */
#define E1000_RCTL_MO             0x00003000    /* multicast offset shift */
#define E1000_RCTL_BAM            0x00008000    /* broadcast enable */
#define E1000_RCTL_SZ             0x00030000    /* rx buffer size */
#define E1000_RCTL_SECRC          0x04000000    /* Strip Ethernet CRC */

#define E1000_TIPG     0x00410/4  /* TX Inter-packet gap -RW */

/* Transmit Descriptor bit definitions */
#define E1000_TXD_CMD_RS     0x00000008 /* Report Status */
#define E1000_TXD_CMD_EOP    0x00000001 /* End of Packet */
#define E1000_TXD_STAT_DD    0x00000001 /* Descriptor Done */

/* Receive Descriptor bit definitions */
#define E1000_RXD_STAT_DD       0x01    /* Descriptor Done */
#define E1000_RXD_STAT_EOP      0x02    /* End of Packet */

struct tx_desc
{
	uint64_t addr;
	uint16_t length;
	uint8_t cso;
	uint8_t cmd;
	uint8_t status;
	uint8_t css;
	uint16_t special;
}__attribute__((packed));

struct tx_pkt
{
	uint8_t buf[TX_PKT_SIZE];
}__attribute__((packed));

struct rx_desc
{
	uint64_t addr;
	uint16_t length;
	uint16_t chksum;
	uint8_t status;
	uint8_t errors;
	uint16_t special;
}__attribute__((packed));

struct rx_pkt
{
	uint8_t buf[RX_PKT_SIZE];
}__attribute__((packed));

int net_pci_attach (struct pci_func *pcif);
int net_pci_transmit (char *data, int len);
int net_pci_receive (char *data);
#endif	// JOS_KERN_E1000_H
