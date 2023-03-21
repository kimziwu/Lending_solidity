// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import './IPriceOracle.sol';
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
ETH를 담보로 사용해서 USDC를 빌리고, 빌려줄 수 있는 서비스
이자율 : 24h - 0.1% 
LTV : 50%
	특정 담보로 빌릴 수 있는 최대 금액
	1ETH=0.5USDC
liquidation threshold : 75%
	청산 임계값
	대출이 담보의 75%를 넘으면 청산됨
담보가격 : oracle

-deposit (ETH, USDC 입금)
-borrow (담보만큼 대출)
-repay (대출상환)
-liquidate (청산하여 USDC 확보) - 청산방법은 적합한것으로 진행

-토큰은 주소로 간주해서 사용
*/

contract DreamAcademyLending {

	IPriceOracle _oracle;
	ERC20 _stable;


	//struct 
    mapping(address=>uint256) _userUSDC; //예금
    mapping(address=>uint256) _userETH; //담보금
    mapping(address=>uint256) _borrow; 
	mapping(address=>uint) _time;


	constructor(IPriceOracle oracle, address usdc) {
		_stable=ERC20(usdc); 
		_oracle=oracle;
	}


	function initializeLendingProtocol(address usdc) public payable {
		/*
		console.log(address(_usdc));
		console.log(address(this));
		console.log(address(msg.sender));
		*/
		
		_stable.transferFrom(msg.sender, address(this), msg.value); 
        console.log(_stable.balanceOf(address(this))); 
	}


	//예금, 토큰주소
	function deposit(address tokenAddress, uint256 amount) public payable {
        if (tokenAddress!=address(0)){ //USDC
            require(_stable.balanceOf(msg.sender)>=amount,""); //??
            _stable.transferFrom(msg.sender, address(this), amount); 
            _userUSDC[msg.sender]=amount;
			_time[msg.sender]=block.number;
        }
        else { // ETH (address(0))
			require(amount>0);
            require(msg.value>=amount);
            _userETH[msg.sender]+=amount;
        }
	}


	function borrow(address tokenAddress, uint256 amount) external payable{
		/*

        require(amount<=_stable.balanceOf(address(this)));

        uint test_amount=_userETH[msg.sender]*_oracle.getPrice(address(0x0))/_oracle.getPrice(tokenAddress)/2-_borrow[msg.sender]; // 대출가능 금액 계산
        require(amount<=test_amount);

        _borrow[msg.sender]+=amount;
		_time[msg.sender]=block.number;

		_stable.transfer(msg.sender, amount);
		*/
	}


	// 상환
	function repay(address tokenAddress, uint256 amount) external payable {
		/*
		require(_stable.balanceOf(msg.sender)>=amount);
		require(_userETH[msg.sender]>=amount);
		_userETH[msg.sender]-=amount;
		_stable.transferFrom(msg.sender, address(this), amount);
		*/
	}


	function liquidate(address user, address tokenAddress, uint256 amount) external {
		/*
		require(_borrow[user]>=amount);
		require((_userETH[user]*_oracle.getPrice(address(0x0))/_oracle.getPrice(tokenAddress))*3/4<_borrow[user]);
        require(_borrow[user]<100 ether || amount==_borrow[user]);

		_borrow[user]-=amount;
		_userETH[user]-=amount;
		_time[user]=block.number;
		*/
	}


	function withdraw(address tokenAddress, uint256 amount) external {
		/*
		if (tokenAddress!=address(0)){
			require(_stable.balanceOf(address(this))>=amount);
			require(_userUSDC[msg.sender]>=amount);

			
		}
		else {
			require(_userETH[msg.sender]>=amount);

		}
		*/
	}

	function getAccruedSupplyAmount(address usdc) public returns (uint256) {

	}


	
}