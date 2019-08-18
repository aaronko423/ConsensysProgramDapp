pragma solidity >=0.4.21 <0.6.0;

import "./erc721.sol";
import "./safemath.sol";

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