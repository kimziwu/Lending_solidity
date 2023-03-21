// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import './IPriceOracle.sol';
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
이자율 : 0.1%
LTV : 50%
liquidation threshold : 75%
*/

contract DreamAcademyLending {

	IPriceOracle _oracle;
	ERC20 _usdc;
    ERC20 _eth;

    mapping(address=>uint) _userUSDC; //예금
    mapping(address=>uint) _userETH; //예금
    mapping(address=>uint) _borrow; //대출





	constructor(IPriceOracle oracle, address usdc) {
		_usdc=ERC20(usdc); //usdc pool
        _eth=ERC20(address(0x0));
		_oracle=oracle;
	}


	function initializeLendingProtocol(address usdc) public payable {
		_usdc.transferFrom(msg.sender, address(this), msg.value);
        console.log(_usdc.totalSupply()); // 총량 확인
	}


	//예금, 주소는 토큰의 주소(예금하고자하는)
	function deposit(address tokenAddress, uint256 amount) public payable {
        

        if (tokenAddress!=address(0)){ //USDC
            require(_usdc.balanceOf(msg.sender)>=amount,"");
            _usdc.transferFrom(msg.sender, address(this), amount);
            _userUSDC[msg.sender]=amount;
            
        }
        else { // ETH
            require(msg.value>0);
            require(msg.value==amount);
            _userETH[msg.sender]+=amount;
        }

	}


	function borrow(address tokenAddress, uint256 amount) external payable{
        require(amount<=_usdc.balanceOf(address(this)));

        uint test_amount=0; // 대출가능 금액 계산
        require(amount<=test_amount);

        
        

        
	}


	// 상환
	function repay(address tokenAddress, uint256 amount) external payable {


	}


	function liquidate(address user, address tokenAddress, uint256 amount) external {

	}


	function withdraw(address tokenAddress, uint256 amount) external {

	}

	function getAccruedSupplyAmount(address usdc) public returns (uint256) {

	}


	
}