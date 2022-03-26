//"SPDX-License-Identifier: APACHE 2.0"

pragma solidity >=0.8.0 <0.9.0;

import "https://github.com/Block-Star-Logic/open-libraries/blob/16a705a5421984ca94dc72fff100cb406ac9aa96/blockchain_ethereum/solidity/V1/libraries/LOpenUtilities.sol";
import "https://github.com/Block-Star-Logic/open-roles/blob/fc410fe170ac2d608ea53e3760c8691e3c5b550e/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRolesManaged.sol";

import "../openblock/OpenRolesSecure.sol";
import "../openblock/IOpenRegister.sol";

import "./IOpenProduct.sol";
import "./OpenProduct.sol";
import "./IOpenProductCore.sol";




contract OpenProductCore is IOpenProductCore, OpenRolesSecure, IOpenRolesManaged { 

    using LOpenUtilities for address; 

    address[] products; 
    uint256[] ids; 

    string name = "RESERVED_OPEN_PRODUCT_CORE"; 
    uint256 version = 1; 

    string registerCA                   = "RESERVED_OPEN_REGISTER";
    string roleManagerCA                = "RESERVED_OPEN_ROLES";

    address registryAddress; 
    IOpenRegister registry; 

    string [] roleNames; 

    mapping(string=>bool) hasDefaultFunctionsByRole;
    mapping(string=>string[]) defaultFunctionsByRole;

    uint256 productIndex = 0; 
    
    mapping(address=>bool) knownByProductAddress; 
    mapping(uint256=>bool) knownByProductId; 
    mapping(uint256=>address) productAddressByProductId; 



    //@ todo implement full product management features 
    constructor (address _registryAddress){ 

        registryAddress = _registryAddress;   
        registry = IOpenRegister(_registryAddress); 
        setRoleManager(registry.getAddress(roleManagerCA));
    }

    function getVersion() override view external returns (uint256 _version){
        return version; 
    }

    function getName() override view external returns (string memory _contractName){
        return name;
    }

    function getDefaultRoles() override view external returns (string [] memory _roleNames){
        return roleNames; 
    }

    function hasDefaultFunctions(string memory _role) override view external returns(bool _hasFunctions){
        return hasDefaultFunctionsByRole[_role];
    } 

    function getDefaultFunctions(string memory _role) override view external returns (string [] memory _functions){
        return defaultFunctionsByRole[_role];
    }

    function getProduct(uint256 _productId) override view external returns (address _productAddress){
        return productAddressByProductId[_productId];
    } 

    function getProducts() override view external returns (address [] memory _products) {
        return products; 
    }

    function getProductIds() override  view external returns (uint256[] memory _ids) {
        return ids; 
    }

    function isVerified(address _product) override view external returns (bool _verified){
        return knownByProductAddress[_product];
    }

    function createProduct(string memory _name, uint256 _price, string memory _currency, address _erc20) override external returns (address _productAddress) {
        uint256 productId_ = productIndex++;
        ids.push(productId_);
        _productAddress = address(new OpenProduct(productId_, _name, _price, _currency, _erc20));
        addProductInternal(_productAddress);
        return _productAddress;
    }

    function removeProduct(address _productAddress) override external returns (bool _removed) {
        return removeProductInternal(_productAddress);        
    }

    // ====================================== INTERNAL =================================================

    function addProductInternal(address _productAddress) internal returns (bool _added) {
        IOpenProduct product = IOpenProduct(_productAddress);
        uint256 productId_ = product.getId(); 
        if(!knownByProductId[productId_]){
            productAddressByProductId[product.getId()] = _productAddress; 
            products.push(_productAddress);
            knownByProductAddress[_productAddress] = true; 
            knownByProductId[productId_] = true; 
            return true; 
        }
        return false; 
    }

    function removeProductInternal(address _productAddress) internal returns (bool _removed){
        IOpenProduct product = IOpenProduct(_productAddress);
        uint256 productId_ = product.getId(); 
        if(knownByProductId[productId_]){
            delete productAddressByProductId[product.getId()]; 
            _productAddress.remove(products);
            delete knownByProductAddress[_productAddress]; 
            delete knownByProductId[productId_]; 
            return true; 
        }
        return false; 
    }
}