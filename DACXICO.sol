pragma solidity ^0.4.25;

import "DACXContract.sol";


contract DACXICO is Ownable {
    using SafeMath for uint;

    mapping(address => bool) whitelist;

    // First date locked team token transfers are allowed
    uint saleEndTime;
    uint saleRate;
    uint saleAmount;

    // Main Token Contract Address
    address maincontract = 0x7F89Feec5389aA3A3755253169909a1Ca2db5a84;
    // CrowdSale Wallet from MainContract will be used as source of funds
    address crowdsale = 0x56390F548cc97FDf187AA2C0bD14c87364C58faD;
    
    address admin;

    modifier onlyAdmin() {
       require(msg.sender == owner || msg.sender == admin);
       _;
    }
    
    event AdminAssigned(address indexed previousAdmin, address indexed newAdmin);

    constructor () public {
       saleEndTime = 0;
       saleRate = 0;
       saleAmount = 0;
       
       admin = owner;
    }

    /**
    * @dev Allows the current owner to set a new Admin that can add/remove whitelisted addresses
    * @param newAdmin The adress to assign as admin
    */
    function assignAdmin(address newAdmin) public onlyOwner {
       require(newAdmin != address(0));
       emit AdminAssigned(admin, newAdmin);
       admin = newAdmin;
     }
  
    /**
    * @dev Allows the current admin to whitelist a new address
    * @param user The adress to add to whitelist
    */
    function whitelistAddress (address user) public onlyAdmin {
        whitelist[user] = true;
    }

    /**
    * @dev Allows the current admin to remove an address from whitelist
    * @param user The adress to remove from whitelist
    */
    function removeAddress (address user) public onlyAdmin {
        whitelist[user] = false;
    }

    /**
    * @dev Allows the current admin to whitelist multiple addresses
    * @param users Adresses to add to whitelist
    */
    function whitelistAddresses (address[] users) public onlyAdmin {
        for (uint i = 0; i < users.length; i++) {
            whitelist[users[i]] = true;
        }
    }
    
    /**
    * @dev Allows the current admin to remove addresses from whitelist
    * @param users Adresses to remove from whitelist
    */
    function removeAddresses (address[] users) public onlyAdmin {
        for (uint i = 0; i < users.length; i++) {
            whitelist[users[i]] = false;
        }
    }

    /**
    * @dev Used by Admin to initiate a new Crowdsale Period
    * @param _endTime The Date sale will end
    * @param _rate Amount of Tokens that will be sent back, per ETH received
    * @param _amount Total Amount of tokens available for sale for this period & rate
    */
    function startICO (uint _endTime, uint _rate, uint _amount) public onlyAdmin {
        require(now > saleEndTime); // Previous sale must end before a new one can be started
        require(now < _endTime); // End Time must be a future date
        require(_rate > 0);     
        // at least 1,000,000 Tokens, Since startICO can not be used till previous ICO ends
        // this prevents accidentally passing uint256 values less than decimal points
        require(_amount > 1000000e18);

        saleEndTime = _endTime;        
        saleRate = _rate;        
        saleAmount = _amount;        

    }

    /**
    * @dev Used by Owner to withdraw ETH funds
    * @param _amount Total Amount of ETH to withdraw
    */
    function withdraw(uint256 _amount) public onlyOwner returns(bool) {
        require(_amount < address(this).balance);
       
        owner.transfer(_amount);
       
        return true;

    }
    
    function killContract() public onlyOwner {
        selfdestruct(owner);
    }    

    function () public payable {
        require(msg.value >= 5e16);     // Amounts less than 0.05 ETH are not allowed
        require(now < saleEndTime);     // No sales after sale ends
        require(whitelist[msg.sender]); // Requesting address must be in the whitelist

        uint256 tokenCount = msg.value * saleRate;
        saleAmount = saleAmount.sub(tokenCount);
        
        DACXTokenT3(maincontract).transferFrom(crowdsale, msg.sender, tokenCount);
    }

}