// SPDX-License-Identifier: APACHE-2.0

pragma solidity ^0.8.15;


interface IOpenProductList {

    function isOnList(address _address) view external returns (bool _onList);

    function getListType() view external returns (string memory _listType);

    function getListName() view external returns (string memory _listName);
    
}