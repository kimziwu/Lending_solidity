// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import './IPriceOracle.sol';
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
ETH를 담보로 사용해서 USDC를 빌리고, 빌려줄 수 있는 서비스
이자율 : 24h - 0.1% 
LTV : 50%        	OOOOOOOOOOOOOOOOOOOOOO
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


    mapping(address=>uint256) _deposits; //예금 USDC
	uint _totalDeposits;
    mapping(address=>uint256) _mortgages; //담보금 BTC
	uint _totalMortgages;
    mapping(address=>uint256) _borrow; // USDC
	uint _totalBorrow;
	mapping(address=>uint) _time;

	mapping(address=>uint) _interests; //이자
	uint _totalInterests;

	uint _totalUsd;
	

	/*
	1block=12secs
	이자율 0.1% 복리
	mortgages*(1+0.001) ** 24h(1) 
	
	borrow(뺏김) -> deposits(받음)

	(block.number*12-최근타임)*borrow?

    time 변수설정
	*/

	uint _updateUsd;
	uint _updateBorrow;
	uint _usdcAccum; 


	constructor(IPriceOracle oracle, address usdc) {
		_stable=ERC20(usdc); 
		_oracle=oracle;

	}

	// _stable은 컨트랙트, usdc 토큰 컨트롤 가능
	function initializeLendingProtocol(address usdc) public payable {
		/*
		console.log(address(_usdc));
		console.log(address(this));
		console.log(address(msg.sender));
		*/
		
		_stable.transferFrom(msg.sender, address(this), msg.value); 
		_totalUsd+=msg.value;
		
		// 1block=12secs
	}

	// address(0x0) : BTC, address(usdc) : USDC
	// tokenAddress=토큰
	function deposit(address tokenAddress, uint256 amount) external payable {
		
		if (tokenAddress!=address(0)){ //USDC
            require(_stable.balanceOf(msg.sender)>=amount);
            require(amount>0); 
            _stable.transferFrom(msg.sender, address(this), amount); 
            _deposits[msg.sender]+=amount;
			_totalDeposits+=amount;
        }
        else { // ETH 
			require(msg.value>0); 
            require(msg.value==amount);
            _mortgages[msg.sender]+=amount;
			_totalMortgages+=amount;
        }
	}


	// 대출
	// tokenAddress 담보 토큰 = ETH, amount 담보 양 
	// 담보를 기반으로 USDC 빌려줌
	function borrow(address tokenAddress, uint256 amount) external payable{
		require(_stable.balanceOf(address(this))>=amount);

		// LTV - 50%
        uint oracle=_oracle.getPrice(address(0x0))/_oracle.getPrice(tokenAddress);
        uint test_amount=_mortgages[msg.sender]*oracle/2-_borrow[msg.sender];
        require(test_amount>=amount);

        _borrow[msg.sender]+=amount;
		_totalBorrow+=amount;
		_stable.transfer(msg.sender, amount);
	}


	// USDC 상환 
	function repay(address tokenAddress, uint256 amount) external payable {
		require(_stable.balanceOf(msg.sender)>=amount);
		require(_borrow[msg.sender]>=amount);

		// 이자 계산해야 함
		_stable.transferFrom(msg.sender, address(this), amount);
		_borrow[msg.sender]-=amount;
        _totalBorrow-=amount;
	}

	// 청산 
	function liquidate(address user, address tokenAddress, uint256 amount) external payable {

		// 현재 담보가격 
		uint256 mortgage = _mortgages[user]*_oracle.getPrice(address(0x0))/_oracle.getPrice(tokenAddress);
		console.log(mortgage);

		// liquidation threshold 
        require(_borrow[user]>=amount);
        require(_borrow[user]>mortgage/2);

        // 청산 금액
        require(_borrow[user]<100 ether || amount==_borrow[user]/4);
		
        _borrow[user]-=amount;
        _totalBorrow-=amount;
        _mortgages[user]-=amount*_oracle.getPrice(tokenAddress)/_oracle.getPrice(address(0x0));
        _totalMortgages-=amount*_oracle.getPrice(tokenAddress)/_oracle.getPrice(address(0x0));
    }


	// 출금 - USDC, ETH
	// mortgage, deposit, interests
	function withdraw(address tokenAddress, uint256 amount) external payable {
		if (tokenAddress!=address(0)){ // USDC - _stable, interests, deposits
			require(_stable.balanceOf(address(this))>=amount);
            //uint pay=amount+_totalInterests*(_deposits[msg.sender]/_totalDeposits);
            _deposits[msg.sender]-=amount;
		    _stable.transferFrom(address(this), msg.sender, amount);
            _totalDeposits-=amount;
        
            // time block 
		}
		else { //BTC
			require(_mortgages[msg.sender]>=amount);
			require(address(this).balance>=amount);

			// 조건검증 repay 상환 50%
            
			uint256 mortgage =_borrow[msg.sender]*_oracle.getPrice(address(this))/_oracle.getPrice(address(0x0));
			require(mortgage<=(_mortgages[msg.sender]-amount)/2,"Liquidation threshold");
    
    
			_mortgages[msg.sender]-=amount;
			msg.sender.call{value:amount}("");
		}
		
	}


	function getAccruedSupplyAmount(address usdc) public returns (uint256) {
		return _deposits[msg.sender]+_totalInterests*(_deposits[msg.sender]/_totalDeposits);
        // 개인 이자 계산 
	}




}