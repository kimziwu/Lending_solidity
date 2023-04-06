// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import './IPriceOracle.sol';
import './math.sol';
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


contract DreamAcademyLending {
	IPriceOracle priceOracle;
	ERC20 usdc;

    uint256 constant public BLOCKS_PER_DAY = 7200;
    // (1+0.001)^(1/7200) * 10^27
    uint256 constant public INTEREST_RATE = 1000000011568290959081926677; // 0.1% daily interest rate
    uint256 constant public COLLATERAL_RATIO = 50; // 50%
    uint256 constant public LIQUIDATION_THRESHOLD = 75; // 75%
    uint256 constant public BLOCK = 12; // 1block=12sec
    uint256 constant RAY=10**27;

    struct Deposit {
        uint256 amount;
        uint256 interest;
        bool flag;
    }
    mapping(address => Deposit) private deposits;
    address [] depositArr;

    struct Borrow {
        uint256 amount;
        uint256 timestamp;
    }
    mapping(address => Borrow) borrows; 

	uint256 totalBorrows;
    uint256 totalBorrowsUpdate;
    
    mapping(address=>uint256) mortgages; 


	constructor(IPriceOracle oracle, address _usdc) {
		usdc=ERC20(_usdc); 
		priceOracle=oracle;
	}

	function initializeLendingProtocol(address _usdc) public payable {
		usdc.transferFrom(msg.sender, address(this), msg.value); 
	}
    
	function deposit(address tokenAddress, uint256 amount) external payable {
        require(tokenAddress == address(usdc) || tokenAddress == address(0), "Invalid token");
        require(amount > 0);
		
        if (tokenAddress == address(usdc)){ 
            require(usdc.balanceOf(msg.sender) >= amount);
            
            Deposit storage deposit = deposits[msg.sender];
            deposit.amount += amount;     
            
            if (deposit.flag == false){
                depositArr.push(msg.sender);
                deposit.flag = true;
            }
            update();
            usdc.transferFrom(msg.sender, address(this), amount);
        }
        else { 
            require(msg.value == amount);
            mortgages[msg.sender] += amount;
        }
	}


	
	function borrow(address tokenAddress, uint256 amount) external payable{
		require(usdc.balanceOf(address(this)) >= amount);
        
        Borrow storage borrow = borrows[msg.sender];

        // interest
        uint256 timeInterval = block.number * BLOCK - borrow.timestamp;   
        borrow.amount = Interest(borrow.amount, INTEREST_RATE, timeInterval); 
        borrow.timestamp = block.number * BLOCK;

		// LTV - 50%
        uint256 oracle = priceOracle.getPrice(address(0x0)) / priceOracle.getPrice(tokenAddress); 
        uint256 availableAmount = mortgages[msg.sender] * oracle * COLLATERAL_RATIO / 100 - borrow.amount;
        require(availableAmount >= amount);

        borrow.amount += amount;
		totalBorrows += amount;
		usdc.transfer(msg.sender, amount);
	}


	function repay(address tokenAddress, uint256 amount) external payable {
		require(usdc.balanceOf(msg.sender) >= amount);
		require(borrows[msg.sender].amount >= amount);

		borrows[msg.sender].amount -= amount;
        totalBorrows -= amount;
        
        usdc.transferFrom(msg.sender, address(this), amount);
	}


	function liquidate(address user, address tokenAddress, uint256 amount) external payable {
        require(borrows[user].amount >= amount);
		
        uint256 oracle = priceOracle.getPrice(address(0x0)) / priceOracle.getPrice(tokenAddress);
        uint256 mortgage = mortgages[user] * oracle;

        // liquidation threshold & testcode 
        require(borrows[user].amount > mortgage * LIQUIDATION_THRESHOLD / 100);
        require(borrows[user].amount < 100 ether || amount == borrows[user].amount / 4);
		
        borrows[user].amount -= amount;
        totalBorrows -= amount;
        
        oracle = priceOracle.getPrice(tokenAddress) / priceOracle.getPrice(address(0x0));
        mortgages[user] -= amount * oracle;
    }


	function withdraw(address tokenAddress, uint256 amount) external payable {
        if (tokenAddress == address(usdc)){ 
			require(usdc.balanceOf(address(this)) >= amount);
     
            uint256 withdrawAmount = getAccruedSupplyAmount(address(usdc));
            require(withdrawAmount >= amount);

            usdc.transfer(msg.sender, amount);
		}
		else { 
            uint256 timeInterval = block.number * BLOCK - borrows[msg.sender].timestamp;
            borrows[msg.sender].amount = Interest(borrows[msg.sender].amount, INTEREST_RATE, timeInterval);
            borrows[msg.sender].timestamp = block.number * BLOCK;

            
			uint256 mortgage = borrows[msg.sender].amount * priceOracle.getPrice(address(usdc)) / priceOracle.getPrice(address(0x0));
			require(mortgage <= (mortgages[msg.sender] - amount) * LIQUIDATION_THRESHOLD / 100);
    
			mortgages[msg.sender] -= amount;
			msg.sender.call{value:amount}("");
		}
	}


	function getAccruedSupplyAmount(address usdc) public returns (uint256) {
        update(); 
		return deposits[msg.sender].amount + deposits[msg.sender].interest; 
	}
   

    // https://github.com/wolflo/solidity-interest-helper 
    function Interest(uint principal, uint rate, uint age) internal returns (uint) {
        return SafeMath.rmul(principal, SafeMath.rpow(rate, age));
    }
 

    function update() internal {
        uint256 cnt = depositArr.length;
        uint256 depositsAccum;
        
        uint256 totalDepositsAccum = usdc.balanceOf(address(this));
        uint256 totalBorrowsAccum = totalBorrows;
        uint256 timeInterval = block.number * BLOCK - totalBorrowsUpdate;

        totalBorrowsAccum = Interest(totalBorrowsAccum, INTEREST_RATE, timeInterval);
        totalBorrowsUpdate = block.number * BLOCK;
        
        
        if(totalDepositsAccum == 0) return;
        uint256 interest = totalBorrowsAccum - totalBorrows;
        for(uint i = 0; i < cnt; i++){
            address user = depositArr[i];
     
            depositsAccum = deposits[user].amount;
            deposits[user].interest += interest * depositsAccum / totalDepositsAccum;
        }
        totalBorrows = totalBorrowsAccum;
    }
}