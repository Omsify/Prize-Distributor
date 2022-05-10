// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./imported/IERC20.sol";
import "./imported/IERC721.sol";
import "./VRFv2Consumer.sol";

contract PrizeDistributor is VRFv2Consumer {
    event Transfer();

    constructor(uint64 subscriptionId) VRFv2Consumer(subscriptionId) {}

    function distributeToAddresses(
        uint256 _eachWinnerPrize,
        address[] memory _addresses
    ) public payable {
        require(
            _eachWinnerPrize * _addresses.length <= msg.value,
            "Not enough coins sent"
        );
        for (
            uint256 currentAddress = 0;
            currentAddress < _addresses.length;
            currentAddress++
        ) {
            payable(_addresses[currentAddress]).transfer(_eachWinnerPrize);
        }
        emit Transfer();
    }

    function distributeERC20ToAddresses(
        uint256 _eachWinnerPrize,
        address[] memory _addresses,
        address _ERC20Address
    ) public {
        IERC20 token = IERC20(_ERC20Address);
        require(
            _eachWinnerPrize * _addresses.length <= token.balanceOf(msg.sender),
            "Not enough tokens in your wallet"
        );
        for (
            uint256 currentAddress = 0;
            currentAddress < _addresses.length;
            currentAddress++
        ) {
            token.transferFrom(
                msg.sender,
                _addresses[currentAddress],
                _eachWinnerPrize
            );
        }
        emit Transfer();
    }

    function distributeERC721ToAddresses(
        address[] memory _addresses,
        uint256[] memory _tokenIDs,
        address _ERC721Address
    ) public {
        require(
            _addresses.length == _tokenIDs.length,
            "_addresses and _tokenIDs lengths do not match"
        );
        IERC721 token = IERC721(_ERC721Address);
        for (
            uint256 currentAddress = 0;
            currentAddress < _addresses.length;
            currentAddress++
        ) {
            token.transferFrom(
                msg.sender,
                _addresses[currentAddress],
                _tokenIDs[currentAddress]
            );
        }
        emit Transfer();
    }

    /// @dev Chooses winners out of participants array. Must be called after random number confirmation. One address is able to win multiple times.
    function getRandomWinners(
        uint256 _winnersNum,
        address[] memory _participants
    ) private view returns (address[] memory) {
        require(
            randomWordByAddress[msg.sender] != 0,
            "Request a random number first or wait untill it's confirmed"
        );
        address[] memory winners = new address[](_winnersNum);
        for (uint256 i = 0; i < _winnersNum; i++) {
            winners[i] = _participants[
                uint256(
                    keccak256(abi.encode(randomWordByAddress[msg.sender], i))
                ) % _participants.length
            ];
        }
        return winners;
    }

    function distributeToRandomAddresses(
        address[] calldata _participants,
        uint256 _winnersNum,
        uint256 _eachWinnerPrize
    ) external payable {
        distributeToAddresses(
            _eachWinnerPrize,
            getRandomWinners(_winnersNum, _participants)
        );
    }

    function distributeERC721ToRandomAddresses(
        address[] calldata _participants,
        uint256[] calldata _tokenIDs,
        address _ERC721Address
    ) external {
        distributeERC721ToAddresses(
            getRandomWinners(_tokenIDs.length, _participants),
            _tokenIDs,
            _ERC721Address
        );
    }

    function distributeERC20ToRandomAddresses(
        address[] calldata _participants,
        uint256 _winnersNum,
        uint256 _eachWinnerPrize,
        address _ERC20Address
    ) external {
        distributeERC20ToAddresses(
            _eachWinnerPrize,
            getRandomWinners(_winnersNum, _participants),
            _ERC20Address
        );
    }
}
