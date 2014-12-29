#include <kern/e1000.h>

// LAB 6: Your driver code here

volatile uint32_t *net_pci_addr;

// Transmit decriptor array and packet buffer (continuous memory)
struct tx_desc tx_desc_arr[PCI_TXDESC] ;//__attribute__ ((aligned (16)));
struct tx_pkt tx_pkt_buf[PCI_TXDESC];

// Transmit decriptor array and packet buffer (continuous memory)
struct rx_desc rx_desc_arr[PCI_RXDESC] ;//__attribute__ ((aligned (16)));
struct rx_pkt rx_pkt_buf[PCI_RXDESC];


int
net_pci_attach(struct pci_func *pcif){

	int i = 0;
	// Register the PCI device and enable
	pci_func_enable(pcif);

	// Provide the memory for the PCI device
	net_pci_addr = mmio_map_region(pcif->reg_base[0], pcif->reg_size[0]);
	// Check to see if the correct value gets printed
	cprintf("NET PCI status: %x\n", net_pci_addr[E1000_STATUS]);

	// Initialize transmit descriptor array and packet buffer (not necessarily needed)
	memset(tx_desc_arr, 0, sizeof(struct tx_desc) * PCI_TXDESC);
	memset(tx_pkt_buf, 0, sizeof(struct tx_pkt) * PCI_TXDESC);
	
	/* Transmit initialization */
	// Transmit descriptor base address registers init
	net_pci_addr[E1000_TDBAL] = PADDR(tx_desc_arr);
	net_pci_addr[E1000_TDBAH] = 0x0;

	// Transmit descriptor length register init
	net_pci_addr[E1000_TDLEN] = sizeof(struct tx_desc) * PCI_TXDESC;

	// Transmit descriptor head and tail registers init
	net_pci_addr[E1000_TDH] = 0x0;
	net_pci_addr[E1000_TDT] = 0x0;

	// Transmit control register init
	// 1st bit
	net_pci_addr[E1000_TCTL] = E1000_TCTL_EN;
	// 2nd bit
	net_pci_addr[E1000_TCTL] |= E1000_TCTL_PSP;
	// TCTL-CT starts from 4th bit and extends to 11th bit
	// clear all those bits and set it to 10h (11:4) (as per manual)
	net_pci_addr[E1000_TCTL] &= ~E1000_TCTL_CT;
	net_pci_addr[E1000_TCTL] |= (0x10) << 4;
	// TCTL-COLD starts from 12the bit and extends to 21st bit
	// clear all those bits and set i to 40h (21:12) (as per manual)
	net_pci_addr[E1000_TCTL] &= ~E1000_TCTL_COLD;
	net_pci_addr[E1000_TCTL] |= (0x40) << 12;

	/* Transmit IPG register init */
	// Set to zero first
	net_pci_addr[E1000_TIPG] = 0x0;
	// IPGT value 10 for IEEE 802.3 standard (as per maunal)
	net_pci_addr[E1000_TIPG] |= 0xA;
	// IPGR1 2/3 the value of IPGR2 as per IEEE 802.3 standard (as per manual)
	// Starts from the 10th bit
	net_pci_addr[E1000_TIPG] |= (0x4) << 10;
	// IPGR2 starts from the 20th bit, value = 6(as per manual)
	net_pci_addr[E1000_TIPG] |= (0x6) << 20; 

	/* Receive Initialization */
	// Program the Receive Address Registers
	net_pci_addr[E1000_RAL] = 0x12005452;
	net_pci_addr[E1000_RAH] = 0x5634 | E1000_RAH_AV; // HArd coded mac address. (needed to specify end of RAH)
	net_pci_addr[E1000_MTA] = 0x0;

	// Program the Receive Descriptor Base Address Registers
	net_pci_addr[E1000_RDBAL] = PADDR(rx_desc_arr);
    net_pci_addr[E1000_RDBAH] = 0x0;

	// Set the Receive Descriptor Length Register
	net_pci_addr[E1000_RDLEN] = sizeof(struct rx_desc) * PCI_RXDESC;

    // Set the Receive Descriptor Head and Tail Registers
	net_pci_addr[E1000_RDH] = 0x0;
	net_pci_addr[E1000_RDT] = 0x0;

	// Initialize the Receive Control Register
	net_pci_addr[E1000_RCTL] |= E1000_RCTL_EN;
	// Bradcast set 1b
	net_pci_addr[E1000_RCTL] |= E1000_RCTL_BAM;
	// CRC strip
	net_pci_addr[E1000_RCTL] |= E1000_RCTL_SECRC;
	// Associate the descriptors with the packets. (one to one mapping)
	for (i = 0; i < PCI_TXDESC; i++) {
		tx_desc_arr[i].addr = PADDR(tx_pkt_buf[i].buf);
		tx_desc_arr[i].status |= E1000_TXD_STAT_DD;
		rx_desc_arr[i].addr = PADDR(rx_pkt_buf[i].buf);
	}	
	return 0;
}

int
net_pci_transmit(char *data, int len)
{
	cprintf("\n The length in kern space is:%d", len);
	//data = "hello world";
	//len = strlen(data);
	if (len > TX_PKT_SIZE) {
		return -1;
	}
	// Transmit descriptor tail register. (tdt is an index into the descriptor array)
	uint32_t tail = net_pci_addr[E1000_TDT];

	// Use the DD bit, which is set by the PCI device.
	if (tx_desc_arr[tail].status & E1000_TXD_STAT_DD) {
		memmove(tx_pkt_buf[tail].buf, data, len);
		tx_desc_arr[tail].length = len;
		// Clear the DD bit and set the RS bit for feedback and mark the end of packet (necessary).
		tx_desc_arr[tail].status = 0;
		tx_desc_arr[tail].cmd |=  E1000_TXD_CMD_RS | E1000_TXD_CMD_EOP; //This has to be enabled...for HW to process the packet.
		// circular queue
		net_pci_addr[E1000_TDT] = (tail+1) % PCI_TXDESC;
		return 0;
	}
	else {	
		return -1;
	}
}

int
net_pci_receive(char *data) {
	uint32_t tail = net_pci_addr[E1000_RDT];
	// if Packet is has DD bit set, then start processing.
	if (rx_desc_arr[tail].status & E1000_RXD_STAT_DD) {
		// For now, no need to process multi frame data.
		if (!(rx_desc_arr[tail].status & E1000_RXD_STAT_EOP)) {
			panic("Don't allow jumbo frames!\n");
		}
		uint32_t len = rx_desc_arr[tail].length;
		memmove(data, rx_pkt_buf[tail].buf, len);
		// Unset the status (just the opposite of Transmit.
		rx_desc_arr[tail].status &= ~E1000_RXD_STAT_DD;
		rx_desc_arr[tail].status &= ~E1000_RXD_STAT_EOP;
		net_pci_addr[E1000_RDT] = (tail + 1) % 64;
		// return the length to say how much data has been transferred.
		return len;
	}
	return -1;
}
