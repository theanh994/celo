// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FreelancePayment {
    IERC20 public immutable cUSD;

    struct Invoice {
        address freelancer;
        address client;
        uint256 amount;
        bool paid;
        bool claimed;
    }

    mapping(uint256 => Invoice) public invoices;
    uint256 public invoiceCount;

    event InvoiceCreated(uint256 indexed id, address freelancer, address client, uint256 amount);
    event InvoicePaid(uint256 indexed id);
    event InvoiceClaimed(uint256 indexed id, uint256 amount);

    constructor(address _cUSD) {
        cUSD = IERC20(_cUSD);
    }

    function createInvoice(address _client, uint256 _amount) external {
        require(_client != address(0), "Invalid client");
        require(_amount > 0, "Amount > 0");

        uint256 id = invoiceCount++;
        invoices[id] = Invoice(msg.sender, _client, _amount, false, false);
        emit InvoiceCreated(id, msg.sender, _client, _amount);
    }

    function payInvoice(uint256 _id) external {
        Invoice storage inv = invoices[_id];
        require(msg.sender == inv.client, "Only client");
        require(!inv.paid, "Already paid");

        require(cUSD.transferFrom(msg.sender, address(this), inv.amount), "Transfer failed");
        inv.paid = true;
        emit InvoicePaid(_id);
    }

    function claimInvoice(uint256 _id) external {
        Invoice storage inv = invoices[_id];
        require(msg.sender == inv.freelancer, "Only freelancer");
        require(inv.paid, "Not paid");
        require(!inv.claimed, "Already claimed");

        inv.claimed = true;
        require(cUSD.transfer(msg.sender, inv.amount), "Claim failed");
        emit InvoiceClaimed(_id, inv.amount);
    }

    function getInvoice(uint256 _id) external view returns (Invoice memory) {
        return invoices[_id];
    }
}