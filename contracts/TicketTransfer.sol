pragma solidity >=0.4.21 <0.6.0;

import "./TicketCreation.sol";

/// @title TicketTransfer contract
/// @notice this contract mainly deals with ticket transfers as well as fund transfers in the primary and secondary markets
contract TicketTransfer is TicketCreation {

    /// @notice defines the state of each ticket in the secondary market, follows the logical flow that the purchase must be approved by a buyer
    /// before the ticket can be sold (i.e. ownership transfer) by the seller to the buyer in the secondary market
    enum SecondaryMarketStatus {
    PendingApproval,
    ApprovedByBuyer,
    OwnershipTransferred,
    DoneDeal
    }

    uint64 commissionFactor;

    /// @notice defines the amount of commission the contract deployer will take from ticket sales in the secondary market (e.g. 30 means 1/30 ~ 3.3%)
    constructor() public {
        commissionFactor = 30;
    }

    /// @notice creates (1) an event whenever a transfer of ticket ownership occurs; and (2) an event whenever a buyer approves him/herself as the buyer of a ticket in the secondary market
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _ticketId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _ticketId);

    /// @notice maps ticket ID to funds to be sent to the seller in the secondary market
    mapping (uint256 => uint256) ticketIdToPending;
    /// @notice maps ticket ID to the previous owner (i.e. seller) of the ticket (used below to direct fund flows to the seller after ticket ownership has been transferred to the new buyer)
    mapping (uint256 => address) ticketIdToOldOwner;
    /// @notice maps ticket ID to the address of the approved buyer
    mapping (uint256 => address) public approvedBuyers;

    /// @notice modifier disallows the seller making the function call (e.g. a seller should not be able to force a user to approve him/herself as buyer of the ticket)
    modifier notSeller(uint256 _ticketId){
        require(msg.sender != ticketsToOwner[_ticketId], "You are not the buyer.");
        _;
    }

    /// @notice modifier disallows the contract deployer making the function call (e.g. contract deployer cannot force-sell its tickets to any users)
    modifier notContractDeployer(){
        require(msg.sender != contractDeployer, "You are the contract deployer.");
        _;
    }

    /// @notice modifier requires the function to be called by the ticket owner
    modifier ownsTicket(uint256 _ticketId){
        require(ticketsToOwner[_ticketId] == msg.sender, "You don't own the ticket.");
        _;
    }

    /// @notice below functions are simple getter functions for various variables and mappings
    function getContractDeployer() public view returns (address) {
        return contractDeployer;
    }

    function getTicketCount() public view returns (uint256) {
        return tickets.length;
    }

    function balanceOf(address _owner) external view returns (uint256){
        return ownerToQuantity[_owner];
    }

    function ownerOf(uint256 _ticketId) external view returns (address){
        return ticketsToOwner[_ticketId];
    }

    function getPrice(uint256 _ticketId) public view returns (uint256) {
        return tickets[_ticketId].price;
    }

    function getStatus(uint256 _ticketId) public view returns (uint256) {
        return tickets[_ticketId].marketStatus;
    }

    /// @notice when buyer clicks on 'Purchase', this function is called to handle the transfer of ticket ownership from contract deployer to buyer
    /// @notice function requires the buyer to have an account and have sufficient funds to pay for the ticket
    /// @notice relevant mappings are updated as a result of the ticket ownership transfer and a transfer event is emitted
    /// @param _from takes in the seller (i.e. contract deployer) address
    /// @param _to takes in the buyer address
    /// @param _ticketId takes in the ticket ID of the ticket
    function transferFrom(address _from, address _to, uint256 _ticketId) external payable checkIfPaused() notContractDeployer() {
        require(adToUserId[_to] > 0, "Please create an account first."); /* Requires user to have an account */
        require(msg.value == (tickets[_ticketId].price)*1 ether, "Not enough money."); /* Requires buyer to pay the price of ticket */
        ticketsToOwner[_ticketId] = _to;
        ownerToQuantity[_from] = ownerToQuantity[_from].sub(1);
        ownerToQuantity[_to] = ownerToQuantity[_to].add(1);
        emit Transfer(_from, _to, _ticketId);
    }

    /// @notice function is called automatically after the above 'transferFrom' goes through, funds are transferred to contract deployer from the contract
    /// @param _ticketId takes in the ticket ID of the ticket
    function transferEthToCD(uint256 _ticketId) external payable checkIfPaused() notContractDeployer() {
        contractDeployer.transfer((tickets[_ticketId].price) * 1 ether);
    }

    /// @notice function allows the ticket owner only to change the price of the ticket
    /// @param _ticketId takes in the ticket ID of the ticket
    /// @param _newPrice takes in the new price of the ticket
    /// @return returns the new price of the ticket
    function priceRevise(uint256 _ticketId, uint256 _newPrice) external checkIfPaused() ownsTicket(_ticketId) returns(uint256) {
        tickets[_ticketId].price = _newPrice;
    }

    /// @notice when user clicks on 'Approve', this function approves the user as a buyer of the ticket in the secondary market
    /// @notice function requires the buyer to have an account and have sufficient funds to pay for the ticket
    /// @notice the funds paid by the buyer gets stored in a mapping which maps the ticket ID to the amount paid, this amount is later released to the seller
    /// @notice the ticket's secondary market status becomes 1 i.e. approvedByBuyer after approval takes place
    /// @param _approved takes in the approved buyer's address
    /// @param _ticketId takes in the ticket ID of the ticket
    function approve(address _approved, uint256 _ticketId) external payable checkIfPaused() notSeller(_ticketId) {
        require(adToUserId[msg.sender] > 0, "Please create an account first.");
        require(msg.value == (tickets[_ticketId].price) * 1 ether, "Not enough money."); /* Requires buyer to pay the price of ticket */
        approvedBuyers[_ticketId] = _approved; /* Buyer approves him/herself for the ticket, goes into the approved buyer mapping */
        ticketIdToPending[_ticketId] = msg.value; /* Buyer's money gets stored in the contract, so we store it in a temp mapping */
        tickets[_ticketId].marketStatus = 1;
        emit Approval(ticketsToOwner[_ticketId], _approved, _ticketId);
    }

    /// @notice simple getter function
    function getApprovedBuyer(uint256 _ticketId) public view returns(address){
        return approvedBuyers[_ticketId];
    }

    /// @notice when seller clicks on 'Sell', this function handles the transfer of ticket ownership from the seller to the approved buyer in the secondary market
    /// @notice the functionalities are similar to the 'transferFrom' function, only main difference is that this deals with transfers in the secondary market
    /// @notice the ticket's secondary market status becomes 2 i.e. ownershipTransferred after transfer takes place
    /// @notice after transfer, the approvedBuyer mapping for the ticket gets deleted as it is no longer needed in storage (can save gas)
    /// @param _to takes in the buyer's address
    /// @param _ticketId takes in the ticket ID of the ticket
    function transferFromSecond(address _to, uint256 _ticketId) external checkIfPaused() ownsTicket(_ticketId) {
        require(adToUserId[msg.sender] > 0, "Please create an account first.");
        require(tickets[_ticketId].marketStatus == 1, "Not yet approved by any buyer.");
        require(approvedBuyers[_ticketId] == _to, "This is not an approved buyer.");
        ticketsToOwner[_ticketId] = _to;
        ticketIdToOldOwner[_ticketId] = msg.sender;
        ownerToQuantity[msg.sender] = ownerToQuantity[msg.sender].sub(1);
        ownerToQuantity[_to] = ownerToQuantity[_to].add(1);
        tickets[_ticketId].marketStatus = 2;
        delete(approvedBuyers[_ticketId]); /* Can be deleted to refund gas */
        emit Transfer(msg.sender, _to, _ticketId);
        }

    /// @notice similar to the 'transferEthToCD' function, this function is called automatically after 'transferFromSecond' goes through
    /// @notice function requires the msg.sender to be the seller of the ticket (i.e. the 'previous' owner, retrieved from the 'ticketIdToOldOwner' mapping)
    /// @notice funds are released to seller and the contract deployer (commission) using the 'ticketIdToPending' mapping which keeps track of the amount paid by buyer
    /// @notice two mappings can be deleted after transfer is done as they are no longer needed in storage (can save gas)
    /// @notice the ticket's secondary market status becomes 3 i.e. DoneDeal
    /// @param _ticketId takes in the ticket ID of the ticket
    function transferEthSecond(uint256 _ticketId) external payable checkIfPaused() {
        require(tickets[_ticketId].marketStatus == 2, "Ticket not yet transferred.");
        require(ticketIdToOldOwner[_ticketId] == msg.sender, "You cannot run this operation.");
        tickets[_ticketId].marketStatus = 3;
        address payable receiver = msg.sender;
        uint256 commissionAmount = ticketIdToPending[_ticketId]/commissionFactor;
        uint256 sellerAmount = ticketIdToPending[_ticketId] - commissionAmount;
        contractDeployer.transfer(commissionAmount);
        receiver.transfer(sellerAmount);
        delete(ticketIdToPending[_ticketId]);
        delete(ticketIdToOldOwner[_ticketId]);
    }


    /// @notice as this is a test Dapp, this function allows the contract deployer to remove the contract after testing
    function kill() external onlyContractDeployer() {
        selfdestruct(contractDeployer);
    }
}