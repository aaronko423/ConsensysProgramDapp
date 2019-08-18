#### Design Patterns

* (1) Withdrawal patterns

Both the 'transferFrom' function and the 'transferFromSecond' function deal with the transfer of ticket ownership in the primary and secondary markets, respectively, whereas the 'transferEthToCD' function and the 'transferEthSecond' function deal with the transfer of funds between counterparties in the primary and secondary markets, respectively.

The separation of these two types of functions (one dealing with changes in state variables, and the other dealing with the transfer of funds) follow the recommended 'withdrawal' design pattern. Even an external calling contract (i.e. the attacker) with a fallback function that is deliberately designed to fail cannot completely 'poison' the core functionalities of the Dapp as the transfer of ticket ownership between the relevant parties (i.e. the 'transferFrom' and 'transferFromSecond' functions) will still function normally. Only the transfer of funds in this case will stop working.

It's therefore important to isolate the fund transfer function by itself or else an attacker can completely prevent the core functionalities of the Dapp from working by designing a failed fallback function in its contract.

* (2) Restricting access

Multiple modifiers have been implemented in order to limit the function call abilities by certain types of users. This is to prevent users from 'cheating' the Dapp and undermining the core functionalities of the Dapp.

For example, a modifier named 'contractDeployerOnly' is created to ensure the ticket creation function can only be called by the contract deployer (i.e. the original ticket issuer). This is to prevent any users from creating fake tickets on the blockchain. A modifer named 'ownsTicket' also ensures functions such as revising the price of the ticket ('priceRevise') and resale in the secondary market ('transferFromSecond') can only be done by someone who actually owns that ticket. Finally, the modifier named 'notSeller' also ensures the 'approve' function cannot be called by the seller in a transaction or else sellers can force any users to be approved buyers of their tickets in the secondary market.

* (3) State-reliant actions (aka "state machine")

The SecondaryMarketStatus state of each ticket, namely PendingApproval, ApprovedByBuyer, OwnershipTransferred, DoneDeal, ensures certain functions can only be called when a particular state condition is met. Setting up these conditions ensures a logical, enforceable progression of steps within the smart contracts. 

For example, the 'transferFromSecond' function, i.e. ticket ownership transfer, function can only be called if the state condition of 'ApprovedByBuyer' has occurred, meaning there must first be an approved buyer. Similarly, the 'transferEthSecond' function, i.e. fund transfer function, can only be called if the state condition of 'OwnershipTransferred' has occurred, meaning money will only be sent to the seller if the ticket ownership has been successfully transferred from seller to buyer.

* (4) Circuit breaker

The smart contracts have a circuit breaker which can be called only by the contract deployer ('circuitBreaker' function in TicketCreation.sol). In case there are malicious attacks on the smart contracts, the contract deployer or owner of the Dapp can make all function calls fail in order to buy time and find a solution.