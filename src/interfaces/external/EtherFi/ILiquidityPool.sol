// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

interface ILiquidityPool {
    function deposit() external payable returns (uint256);
    function deposit(address _referral) external payable returns (uint256);
    function deposit(address _user, address _referral) external payable returns (uint256);
    function depositToRecipient(address _recipient, uint256 _amount, address _referral) external returns (uint256);

    function withdraw(address _recipient, uint256 _amount) external returns (uint256);

    function getTotalPooledEther() external view returns (uint256);
    function sharesForAmount(uint256 _amount) external view returns (uint256);
    function amountForShare(uint256 _share) external view returns (uint256);
}
