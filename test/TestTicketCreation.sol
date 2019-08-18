pragma solidity >=0.4.21 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/TicketTransfer.sol";

contract TestTicketTransfer {
  /// @notice The address of the deployed contract to be tested
  TicketTransfer ticketTransfer = TicketTransfer(DeployedAddresses.TicketTransfer());
  /// @notice Instantiating another contract, workaround to make address(this) the Contract Deployer to test 'CD only' functions
  TicketTransfer ticketTransferDeployer = new TicketTransfer();

  bool public contractPaused = false;

  /// @notice The info of the user that will be used for testing
  string firstName = "Aaron";
  string lastName = "Ko";
  uint256 expectedUserId = 1;

  /// @notice The info of the tickets that will be used for testing
  string eventName = "US Open";
  string description = "Front Row Seats";
  uint256 price = 2;
  uint256 expectedTicketId = 0;

  string eventName2 = "French Open";
  string description2 = "Back Row Seats";
  uint256 price2 = 1;

  string eventName3 = "Australian Open";
  string description3 = "Box Seats";
  uint256 price3 = 1;

  /// @notice The address of this test contract
  address thisContract = address(this);

/// @notice BELOW FIVE TESTS RELATE TO TICKETCREATION.SOL

  /// @notice Making sure the contract deployer can call the circuit breaker and pause the contract
  function testCircuitBreaker() public {
    contractPaused = ticketTransferDeployer.circuitBreaker();

    AssertBool.equal(contractPaused, true, "Contract becomes paused after running circuit breaker.");
  }

  /// @notice Testing the createAccount() function, ensuring user will get added to the adToUser mapping after creation
  function testUserCanCreateAccount() public {
    contractPaused = false;

    uint256 createdUserId = ticketTransfer.createAccount(firstName, lastName);

    AssertUint.equal(createdUserId, expectedUserId, "Adds to adToUser mapping.");
  }

  /// @notice Testing the createAccount() function when circuit breaker is on, making sure no accounts can be created
  function testCannotCreateAccountWhenPaused() public {
    ticketTransferDeployer.circuitBreaker();

    ticketTransferDeployer.createAccount(firstName, lastName);

    AssertUint.isBelow(ticketTransferDeployer.adToUserId(msg.sender), 1, "Account cannot be created due to circuit breaker.");
  }

  /// @notice Testing the createTicket() function and making sure it gets added to the ticketsToOwner mapping after creation
  function testOwnerCanCreateTicket() public {
    ticketTransferDeployer.createTicket(eventName, description, price);

    AssertAddress.equal(ticketTransferDeployer.ticketsToOwner(expectedTicketId), thisContract, "Adds to ticketsToOwner mapping.");
  }

  /// @notice Testing the ticketCreate() function and making sure it gets added to the ownerToQuantity mapping after creation
  function testTicketQuantity() public {
    ticketTransferDeployer.createTicket(eventName2, description2, price2);
    ticketTransferDeployer.createTicket(eventName3, description3, price3);

    AssertUint.equal(ticketTransferDeployer.ownerToQuantity(thisContract), 3, "Three tickets have been created in total.");
  }

}