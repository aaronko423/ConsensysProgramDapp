#### Ticket Exchange DAPP README

Problem today:

In today's world, there is a great deal of disconnection between (1) the primary ticketing market (i.e. ticket exchange between original ticket issuers and ticket buyers); and (2) the secondary ticketing market (i.e. ticket exchange between resellers and ticket buyers). 

In the primary market, many ticket issuers (for example sporting or music events) are trying to discourage ticket exchange in the secondary market by, for example, requiring ticket holder's name to match the name on the ticket, otherwise entry to event may be denied. In the secondary market, many resellers (or scalpers) are trying make quick profits by reselling tickets on 'grey markets', oftentimes selling them at ridiculously high prices. Furthermore, many buyers are at risk of purchasing fake/invalid tickets from unauthorized resellers. Buyers in the secondary market do not have effective/efficient ways to verify their tickets.

Centralized secondary market ticketing websites, such as Viagogo and Stubhub, have tried to 'formalize' the secondary ticketing market by facilitating ticket exchange and taking transactions out of the 'grey markets'. However, these websites charge relatively high service fees and still, their presence does not solve the issue of disconnection between the different markets as mentioned above.

Solution:

The purpose of my ticket exchange Dapp is to:- 

(1) align the interests between the primary and the secondary ticketing markets; 

(2) increase transparency of ticket exchange and ownership; 

(3) ensure tickets purchased in the secondary market are legitimate; and 

(4) remove friction (i.e. high service fees) by removing middlemen, such as agents and centralized secondary ticketing websites.

In a nutshell, ticket issuers, lets say Music Festival A, will issue their tickets on the Ethereum blockchain with unique and verifiable ticket IDs. These tickets will be ERC721 non-fungible tokens. Customers will buy tickets directly from Music Festival A with cryptocurrency (currently set to be Ether), and transfer of ownership will be recorded on the blockchain. If the customer wishes to resell the ticket to another person on the Dapp, another buyer would have to first approve him/herself as a buyer of the ticket, and after the approval, the reseller will be able to sell the ticket to this approved buyer. 

As the ticket is issued on the blockchain by the original issuer, any buyer can confirm the ticket's legitimacy. A very small % of all secondary market sales will also be transferred to Music Festival A. This helps align the interests of the primary and secondary ticketing markets.

#### Project Design

* Initial project setup - this is a truffle project, and the project directories were set up by executing truffle init on the terminal. Smart contracts are kept in the 'contracts' folder, migration files (initial migration and contract migration) are kept in the 'migration' folder, unit tests (done in both Solidity and Javascript) are kept in the 'test' folder, and the truffle-config.js file has been configured to ensure the Dapp can run on ganache (port 8545) for testing purposes or Rinkeby testnet via Infura. In the package.json file, similar to what was learned from the Pet Shop Tutorial, local install of lite-server will run when npm run dev is executed from terminal at the base directory.

* Smart contracts - all backend logic concerning the creation of tickets, creation of user accounts, transfer of tickets in the primary and secondary markets, and all money flows, are dealt with by smart contracts written in Solidity. The TicketTransfer.sol file inherits the TicketCreation.sol file, which inturn inherits the erc721.sol contract (as tickets are ERC721 tokens). The smart contracts also make use of the OpenZeppelin safemath library (to prevent uint over and underflows).

* Compile and migration - after truffle compile and migrate are executed from terminal at the base directory, the relevant .json files of each contract will be created in the build/contracts directory so that the client (i.e. user interface) is able to communicate with the smart contracts and the relevant functions on the blockchain.

* User interface - src directory contains the user interface files, i.e. html, js and css. Bootstrap is used for the design. The app.js file mainly deals with creating the web3 object in the browser and connecting the user with Metamask, as well as manipulates the DOM according to user interaction with various buttons and options on the Dapp. The current user's ethereum address and also various changes in contract state (for example creation of new tickets) are reflected on the Dapp interface.

Only the contract deployer/tissue issuer can see and interact with the 'Create Ticket' button, while other users/buyers can see and interact with the 'Create Account', 'Purchase', 'Sell' and 'Approve' buttons in the Dapp. The owner of the ticket can also access a 'Change Price' button to change the price of a ticket. All users can click on the 'Owner' button to check the address of the ticket owner.

* Test - running truffle test from the base directory will run the two test files, one written in Solidity and one written in Javascript. At least 5 tests have been written for each of the TicketCreation.sol functions (refer to the Solidity test file) and TicketTransfer.sol functions (refer to the Javascript test file). All tests should pass.

* IPFS (additional requirement) - to satisfy one of the additional requirements, I have also hosted the Dapp on IPFS. The link is https://gateway.ipfs.io/ipfs/QmPTdzzzkUvrkZRMCpY65VqsQP6Rk9uTs1uiN4DQ1wVEyt/. First run ipfs server on terminal, then access the link above, then click on src/ when page loads and the Dapp user interface will load.

#### User Stories

Simple user stories are given below. For details of how different users can interact with the Dapp, please refer to the demo video.

* As a ticket issuer, I am able to create tickets on the Dapp so that users can make ticket purchases on the Dapp and pay me cryptocurrency.

* As a ticket buyer, I am able to purchase tickets on the Dapp with ticket ownership transferred to me automatically.

* As a ticket owner, I am able to verify my ownership of the ticket so that ownership is unique (i.e. cannot be duplicated) and cannot be disputed.

* As a ticket reseller in the secondary ticketing market, I am able to change the price of tickets (as long as I own them) and sell tickets on the Dapp to approved buyers.

* As a ticket issuer, I am able to benefit from ticket sales in the secondary market as a small commission is paid to me everytime a ticket resale occurs in the secondary market.