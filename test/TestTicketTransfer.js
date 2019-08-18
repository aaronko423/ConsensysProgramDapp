const TicketTransfer = artifacts.require("TicketTransfer");

contract('TicketTransfer', accounts => {
    /// Assigning addresses to contract deployer and different users for testing purposes
    const contractDeployer = accounts[0];
    const userOne = accounts[1];
    const userTwo = accounts[2];
 
    /// BELOW SIX TESTS RELATE TO TICKETTRANSFER.SOL

    /// Tests whether the new owner of ticket is userOne after userOne purchases ticket from contract deployer
    it('ticket should be transferred from contract deployer to userOne', async () => {
      const contract = await TicketTransfer.deployed();
      await contract.createTicket("US Open", "Front Row Seats", 1, {from: contractDeployer});
      await contract.createAccount("Aaron", "Ko", {from: userOne});
      await contract.transferFrom(contractDeployer, userOne, 0, { 
          from: userOne,  
          value: Number(web3.utils.toWei("1"))
        });
      const newOwner = await contract.ownerOf(0);
      
      assert.equal(newOwner, userOne);
    });

    /// Tests whether money is successfully transferred to contract deployer's wallet address following userOne's ticket purchase
    it('ticket price gets transferred to contract deployer, CD\'s balance increases', async () => {
       const contract = await TicketTransfer.deployed();
       const oldCDBalance = await web3.eth.getBalance(contractDeployer);
       await contract.transferEthToCD(0, {
           from: userOne
       });
       const newCDBalance = await web3.eth.getBalance(contractDeployer);
       
       assert.isAbove(Number(newCDBalance), Number(oldCDBalance));
      });
    
    /// Tests whether the owner of a ticket can revise the price of the ticket
    it('ticket price revised by owner', async () => {
      const contract = await TicketTransfer.deployed();
      await contract.priceRevise(0, 2, {
        from: userOne
      });
      const newPrice = await contract.getPrice(0);
      assert.equal(newPrice, 2);
      });
    
    /// Tests if a user can approve himself as a buyer of a ticket, whether the approved buyer 'getter' function works, and if the secondaryMarketStatus changes to 'ApprovedByBuyer' after approval
    it('new user approves himself as buyer of the ticket in the secondary market', async () => {
      const contract = await TicketTransfer.deployed();
      await contract.createAccount("Tim", "Ko", {from: userTwo});
      const oldUserTwoBalance = await web3.eth.getBalance(userTwo);
      await contract.approve(userTwo, 0, {
        from: userTwo,
        value: Number(web3.utils.toWei("2"))
      });
      const newUserTwoBalance = await web3.eth.getBalance(userTwo);
      const approvedBuyer = await contract.getApprovedBuyer(0);
      const marketStatus = await contract.getStatus(0);
      
      assert.equal(approvedBuyer, userTwo);
      assert.isAbove(Number(oldUserTwoBalance), Number(newUserTwoBalance));
      assert.equal(marketStatus, 1);
      });
    
    /// Tests if transfer of ticket ownership in the secondary market works, and after transfer, whether the quantity of tickets owned by each user changes
    /// Also tests if the secondaryMarketStatus changes to 'OwnershipTransferred' after the transfer of ticket in the secondary market
    it('ticket ownership gets transferred in the secondary market when seller sells to the approved buyer', async () => {
      const contract = await TicketTransfer.deployed();
      const oldOwner = await contract.ticketsToOwner(0);
      await contract.transferFromSecond(userTwo, 0, {
        from: userOne
      });
      const newOwner = await contract.ticketsToOwner(0);
      const oldOwnerQuantity = await contract.ownerToQuantity(oldOwner);
      const newOwnerQuantity = await contract.ownerToQuantity(newOwner);
      const marketStatus = await contract.getStatus(0);

      assert.equal(oldOwnerQuantity, 0);
      assert.equal(newOwnerQuantity, 1);
      assert.notEqual(oldOwner, newOwner);
      assert.equal(newOwner, userTwo);
      assert.equal(marketStatus, 2);
      });
    
    /// Tests whether the money is successfully transferred to the reseller as well as the contract deployer (as commission) following the secondary market purchase
    /// Also test if the secondaryMarketStatus changes to 'DoneDeal' after the secondary market transaction is completed (i.e. after money is transferred)
    it('ticket price gets transferred to seller, seller\'s balance increases, CD\'s balance also increases due to commission', async () => {
      const contract = await TicketTransfer.deployed();
      const cdOldBalance = await web3.eth.getBalance(contractDeployer);
      const oldUserOneBalance = await web3.eth.getBalance(userOne);
      await contract.transferEthSecond(0, {
        from: userOne
      });
      const cdNewBalance = await web3.eth.getBalance(contractDeployer);
      const newUserOneBalance = await web3.eth.getBalance(userOne);
      const marketStatus = await contract.getStatus(0);

      assert.isAbove(Number(cdNewBalance), Number(cdOldBalance));
      assert.isAbove(Number(newUserOneBalance), Number(oldUserOneBalance));
      assert.equal(marketStatus, 3);
      });
      
  });