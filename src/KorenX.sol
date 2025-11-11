// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

interface IAirdrop {
    function distributeTokens(address[] calldata recipients, uint256[] calldata amounts) external;
}

contract KorenX is ERC20, Ownable {
    
    IAirdrop public airdropContract;  
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10 ** 18;

    event AirdropContractUpdated(address indexed oldAddress, address indexed newAddress);

    error ZeroAddress();
    error MaxSupplyExceeded();

    constructor(
        string memory _name,
        string memory _symbol,
        address _initialHolder
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        if (_initialHolder == address(0)) revert ZeroAddress();
        
        // Mint entire supply to initial holder (deployer or airdrop)
        _mint(_initialHolder, MAX_SUPPLY);
    }

    /**
     * @notice Update the airdrop contract address (admin function)
     * @param _newAirdropAddress New airdrop contract address
     */
    function updateAirdropContract(address _newAirdropAddress) external onlyOwner {
        if (_newAirdropAddress == address(0)) revert ZeroAddress();
        
        address oldAddress = address(airdropContract);
        airdropContract = IAirdrop(_newAirdropAddress);
        
        emit AirdropContractUpdated(oldAddress, _newAirdropAddress);
    }

    /**
     * @notice Check if total supply has been minted
     */
    function isFullyMinted() external view returns (bool) {
        return totalSupply() >= MAX_SUPPLY;
    }

    /**
     * @notice Get token information
     */
    function getTokenInfo() external view returns (
        string memory tokenName,
        string memory tokenSymbol,
        uint256 maxSupply,
        uint256 currentSupply,
        address airdrop
    ) {
        return (
            name(),
            symbol(),
            MAX_SUPPLY,
            totalSupply(),
            address(airdropContract)
        );
    }
}
