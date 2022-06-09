// SPDX-License-Identifier: APACHE-2.0

pragma solidity ^0.8.14;

interface IOpenProductSecuritization  {

    function secureProduct(address _product) external returns (bool _productSecured);

}