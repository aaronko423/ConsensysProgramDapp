
// File: contracts/erc721.sol

pragma solidity >=0.4.21 <0.6.0;

/// @title ERC721 contract
/// @dev all ERC721 tokens must have these functions
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

  function balanceOf(address _owner) external view returns (uint256);

  function ownerOf(uint256 _tokenId) external view returns (address);

  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

  function approve(address _approved, uint256 _tokenId) external payable;
}

// File: contracts/safemath.sol

pragma solidity >=0.4.21 <0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath32
 * @dev SafeMath library implemented for uint32
 */
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint32 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title SafeMath16
 * @dev SafeMath library implemented for uint16
 */
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/TicketCreation.sol

pragma solidity >=0.4.21 <0.6.0;



/// @title TicketCreation contract
/// @notice this contract mainly deals with account creation by users and ticket creation by contract deployer
contract TicketCreation is ERC721 {

  /// @dev using the SafeMath library to prevent uint underflows and overflows
  using SafeMath for uint256;

  /// @notice creates an event whenever a new ticket is created by the contract deployer
  event NewTicket(uint256 indexed ticketId, string eventName, string description, uint256 price, uint256 status);

   address payable contractDeployer;
   bool public contractPaused;

   /// @notice when contract is being deployed, the constructor sets contract deployer to be msg.sender and contract paused (circuit breaker) to be false
   constructor() public {
    contractDeployer = msg.sender;
    contractPaused = false;
    }

  /// @notice struct with attributes that define key information of each user
  struct User {
    address userAd;
    string firstName;
    string lastName;
  }

  /// @notice struct with attributes that define key information of each ticket
  struct Ticket {
    string eventName;
    string description;
    uint256 price;
    uint256 marketStatus;
  }

  /// @notice arrays of users and tickets so that each user and ticket (along with their attributes) can be accessed using an array index
  User[] public users;
  Ticket[] public tickets; /* Array of Tickets */

  /// @notice maps user address to user id
  mapping (address => uint256) public adToUserId;
  /// @notice maps ticket id to user address (shows which user owns a given ticket)
  mapping (uint256 => address) public ticketsToOwner;
  /// @notice maps user address to the number of tickets owned
  mapping (address => uint256) public ownerToQuantity;

  /// @notice modifier limits the function call by contract deployer only
  modifier onlyContractDeployer() {
    require(msg.sender == contractDeployer, 'You are not the contract deployer.');
    _;
  }

  /// @notice modifier requires contract paused to be false i.e. circuit breaker to be off (this modifier is inserted into all functions)
  modifier checkIfPaused() {
    require(contractPaused == false, 'Contract already paused.');
    _;
  }

  /// @notice circuit breaker function can only be called by contract deployer, when circuit breaker is on, any functions with this modifier will not go through
  /// @notice purpose of circuit breaker is to put a pause on smart contracts in case of an attack by a malicious party
  /// @return returns contractPaused as true or false depending on whether the circuit breaker is on or off
  function circuitBreaker() public onlyContractDeployer() returns(bool){
    if(contractPaused == false) {
      contractPaused = true;
    } else{contractPaused = false;}
    return contractPaused;
  }

  /// @notice function handles account creation by users who want to use the Dapp to purchase/resell tickets, user info is appended into the users array
  /// @param _firstName takes user first name
  /// @param _lastName takes user last name
  /// @return returns the user ID
  function createAccount(string calldata _firstName, string calldata _lastName) external checkIfPaused() returns (uint256) {
    uint256 userId = users.push(User(msg.sender, _firstName, _lastName));
    adToUserId[msg.sender] = userId;
    return userId;
  }
  /// @notice function can only be called by contract deployer, handles ticket creation
  /// @notice new tickets are appended to the tickets array, and two relevant mappings are also updated
  /// @notice function emits an event whenever a new ticket is created
  /// @param _eventName takes event name
  /// @param _description takes ticket description
  /// @param _price takes ticket price
  function createTicket(string calldata _eventName, string calldata _description, uint256 _price) external checkIfPaused() onlyContractDeployer() {
    uint256 ticketId = tickets.push(Ticket(_eventName, _description, _price, 0))-1; ///@notice marketStatus is always set as 0 at creation as the ticket is 'pendingApproval' in the secondary market
    ticketsToOwner[ticketId] = msg.sender;
    ownerToQuantity[msg.sender] = ownerToQuantity[msg.sender].add(1);
    emit NewTicket(ticketId, _eventName, _description, _price, 0);
  }
}

// File: contracts/TicketTransfer.sol

pragma solidity >=0.4.21 <0.6.0;


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
