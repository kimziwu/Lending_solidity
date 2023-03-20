// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './IPriceOracle.sol';
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";


/**
이자율 : 0.1%
LTV : 50%
liquidation threshold : 75%
*/

contract DreamAcademyLending {

	IPriceOracle _oracle;
	ERC20 public _usdc;
	uint public _totalUsdc;
	

	

	//묶기
	mapping(address=>uint) public _userEther; //담보배열
	mapping(address=>mapping(address=>uint)) public _borrow; //빌린토큰
	uint public _totalBorrow;
	mapping(address=>uint256) public _time;

	
	mapping(address=>uint) public _userUsdc;
	mapping(address=>uint) public dfd;

	constructor(IPriceOracle oracle, address usdc) {
		_usdc=ERC20(usdc);
		_oracle=oracle;
	}


	function initializeLendingProtocol(address usdc) public payable {
		_usdc.transferFrom(msg.sender, address(this), msg.value);
		_totalUsdc+=msg.value;
		_time[usdc]=block.timestamp;
	}


	//예금
	function deposit(address tokenAddress, uint256 amount) public payable {
		require(amount>0,"");

		// 예금 투입 주소 : tokenAddress
		if (tokenAddress==address(0)){ // ether 
			require(msg.value==amount,"");
			_userEther[msg.sender]+=amount; // 담보저장
		}
		else { //usdc==tokenAddress, 
			require(_usdc.balanceOf(msg.sender)==amount,"");
			_usdc.transferFrom(msg.sender, address(this), amount); 
		}
	}


	function borrow(address tokenAddress, uint256 amount) external payable{
		require(_usdc.balanceOf(address(this))>=amount,"");
	
		// 담보가격
		uint mortgage=_userEther[msg.sender]*_oracle.getPrice(address(0x0));
		// 50%
		uint limit=mortgage/2; 
		if (limit>amount){
			_borrow[msg.sender][tokenAddress]=amount;
		}
		else {
			_borrow[msg.sender][tokenAddress]=limit;
		}

		_usdc.transfer(msg.sender, _borrow[msg.sender][tokenAddress]);
		_totalBorrow+=_borrow[msg.sender][tokenAddress];
		_time[msg.sender]=block.timestamp;
	}


	// 상환
	function repay(address tokenAddress, uint256 amount) external payable {
		require(_usdc.balanceOf(msg.sender)>=amount,"");


	}


	function liquidate(address user, address tokenAddress, uint256 amount) external {

	}


	function withdraw(address tokenAddress, uint256 amount) external {

	}

	function getAccruedSupplyAmount(address usdc) public returns (uint256) {

	}


	
}