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

	ERC20 public _usdc;
	uint public _totalUsdc;
	uint public _initialTime;


	constructor(IPriceOracle oracle, address usdc) {
		_usdc=ERC20(usdc);
		_initialTime=block.number; //1-1
	}


	function initializeLendingProtocol(address usdc) public payable {
		_usdc.transferFrom(msg.sender, address(this), msg.value);
		_totalUsdc+=msg.value;
		_initialTime+=block.number;
	}

	function deposit(address tokenAddress, uint256 amount) external payable {

	}


	function borrow(address tokenAddress, uint256 amount) external {

	}


	function repay(address tokenAddress, uint256 amount) external {

	}


	function liquidate(address user, address tokenAddress, uint256 amount) external {

	}


	function withdraw(address tokenAddress, uint256 amount) external {

	}

	function getAccruedSupplyAmount(address usdc) public returns (uint256) {

	}


	
}