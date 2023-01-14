// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./imported/IERC20.sol";
import "./imported/IERC721.sol";
import "./VRFv2Consumer.sol";

/// @title PrizeDistributor
/// @author OmiAkk
/// @notice ETH is not automatically sent to winners' addresses to prevent Denial of Service
contract PrizeDistributor is VRFv2Consumer {
    enum RaffleType {
        ETH,
        ERC20,
        ERC721
    }

    /// @dev Amount of ether available for withdrawal by an address
    mapping(address => uint256) private ethBalance;

    event RaffleCompleted(
        uint256 seed,
        uint256 participantAmount,
        RaffleType raffleType
    );

    constructor(uint64 subscriptionId) VRFv2Consumer(subscriptionId) {}

    /// @dev Adds a prize to each address ethBalance
    /// @param _eachWinnerPrize ETH prize for each of the addresses
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
            ethBalance[_addresses[currentAddress]] += _eachWinnerPrize;
        }
    }

    /// @dev Sends ERC20 tokens to addresses
    /// @param _ERC20Address Address of ERC20 token to send
    /// @param _eachWinnerPrize ERC20 amount to send to each address
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
    }

    /// @dev Sends ERC721 tokens to addresses
    /// @param _ERC721Address Address of ERC721 token to send
    /// @param _tokenIDs IDs of ERC721 tokens to send to each address
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
    }

    /// @dev Chooses winners out of participants array
    /// @notice Must be called after random number confirmation
    /// @notice One address is able to win multiple times
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

    /// @dev Distributes ETH to random addresses from participants
    /// @notice An address should request randomWords (seed) before distributing to random addresses
    /// @notice One address is able to win multiple times
    function distributeToRandomAddresses(
        address[] calldata _participants,
        uint256 _winnersNum,
        uint256 _eachWinnerPrize
    ) external payable {
        distributeToAddresses(
            _eachWinnerPrize,
            getRandomWinners(_winnersNum, _participants)
        );

        emit RaffleCompleted(
            randomWordByAddress[msg.sender],
            _participants.length,
            RaffleType.ETH
        );
    }

    /// @dev Distributes ERC721 tokens to random addresses from participants
    /// @notice An address should request randomWords (seed) before distributing to random addresses
    /// @notice One address is able to win multiple times
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

        emit RaffleCompleted(
            randomWordByAddress[msg.sender],
            _participants.length,
            RaffleType.ERC721
        );
    }

    /// @dev Distributes ERC20 tokens to random addresses from participants
    /// @notice An address should request randomWords (seed) before distributing to random addresses
    /// @notice One address is able to win multiple times
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

        emit RaffleCompleted(
            randomWordByAddress[msg.sender],
            _participants.length,
            RaffleType.ERC20
        );
    }

    /// @dev Sends all ether availible to withdraw by the caller to him
    function withdrawETH() external {
        uint256 amount = ethBalance[msg.sender];
        ethBalance[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
}
