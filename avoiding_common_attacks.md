#### Avoiding Common Attacks

* (1) Reentrancy

The smart contracts are designed to prevent reentrancy attacks by ensuring changes to state variables occur before any fund transfers. This prevents external contracts or attackers from successfully repeating the call of a fund transfer function before any changes can be made to the contract state.

For example, in TicketTransfer.sol, in the 'transferFromSecond' function which deals with the transfer of funds from contract to seller in the secondary market, I deliberately put the 'change in state' logic i.e. tickets[_ticketId].marketStatus = 3 before the fund transfer logic so that a malicious contract will not be able to repeatedly call this function to keep having money transferred to it as this function requires tickets[_ticketId].marketStatus == 2 in order to run. As a result, the fund transfer logic will not work the second time if it's being called repeatedly as the state would have changed.

* (2) Integer overflows/underflows

Since the max value for uint256 is 2 ^ 256-1, any numbers above will go back to zero, and by the same token, any values below zero will jump to the max value. In order to prevent overflows and underflows of uint256 integers, I've made use of the SafeMath library built by OpenZeppelin in the smart contracts. The use of the SafeMath library will help revert any function calls that lead to overflows and underflows.

* (3) Contract balance dependencies

As it is possible to send ether to a contract address that does not yet exist, it is good practice to never assume that any of my newly deployed smart contracts will have a zero balance. As such, I have ensured that most of my smart contract logic, in particular the 'ifs' or 'require' statements, do not depend on prevailing contract balances to run properly.

* (4) Denial of service

Please refer to my 'Withdrawal pattern' explanation in design_patter_decisions.md. By implementing such design pattern i.e. making fund transfer functionality independent/separated from other smart contract logic, a malacious contract will not be able to completely stop or 'poison' the core functionalities of the Dapp, being the transfer of ticket ownership between sellers and buyers. As such, the smart contracts have been designed to prevent denial of service attacks.