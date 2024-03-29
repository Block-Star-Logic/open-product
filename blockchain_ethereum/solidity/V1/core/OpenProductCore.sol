// SPDX-License-Identifier: APACHE-2.0

pragma solidity ^0.8.15;

import "https://github.com/Block-Star-Logic/open-version/blob/e161e8a2133fbeae14c45f1c3985c0a60f9a0e54/blockchain_ethereum/solidity/V1/interfaces/IOpenVersion.sol";

import "https://github.com/Block-Star-Logic/open-roles/blob/732f4f476d87bece7e53bd0873076771e90da7d5/blockchain_ethereum/solidity/v2/contracts/interfaces/IOpenRolesManaged.sol";

import "https://github.com/Block-Star-Logic/open-roles/blob/732f4f476d87bece7e53bd0873076771e90da7d5/blockchain_ethereum/solidity/v2/contracts/core/OpenRolesSecureCore.sol";


import "../interfaces/IOpenProductCore.sol";
import "../interfaces/IOpenProductSecuritization.sol";

import "./OpenProduct.sol"; 

contract OpenProductCore is OpenRolesSecureCore, IOpenVersion, IOpenRolesManaged, IOpenProductCore { 

    using LOpenUtilities for address; 
    using LOpenUtilities for uint256;

    string name = "RESERVED_OPEN_PRODUCT_CORE"; 
    uint256 version             = 8; 

    string openAdminRole        = "RESERVED_OPEN_ADMIN_ROLE";
    string productManagerRole   = "PRODUCT_MANAGER_ROLE";
    string productViewerRole    = "PRODUCT_VIEWER_ROLE";

    address [] productLog;      // log of all products created and managed
    address[] products;         // products in use
    uint256[] ids; 

    string registerCA               = "RESERVED_OPEN_REGISTER_CORE";
    string roleManagerCA            = "RESERVED_OPEN_ROLES_CORE";
    string productSecurityCA        = "RESERVED_OPEN_PRODUCT_SECURITIZATION";

    address registryAddress; 
    IOpenRegister registry; 
    IOpenProductSecuritization security; 

    string [] roleNames = [openAdminRole, productManagerRole, productViewerRole]; 

    mapping(string=>bool) hasDefaultFunctionsByRole;
    mapping(string=>string[]) defaultFunctionsByRole;

    uint256 productIndex = 1; 
    
    mapping(address=>bool) knownByProductAddress; 
    mapping(uint256=>bool) knownByProductId; 
    mapping(uint256=>address) productAddressByProductId; 
    mapping(string=>address[]) productsByName; 


    //@ todo implement full product management features 
    constructor (address _registryAddress, string memory _dappName) OpenRolesSecureCore(_dappName) { 
        registryAddress = _registryAddress;   
        registry = IOpenRegister(_registryAddress); 
        setRoleManager(registry.getAddress(roleManagerCA));

        addConfigurationItem(_registryAddress);
        addConfigurationItem(address(roleManager));
        security = IOpenProductSecuritization(registry.getAddress(productSecurityCA));
        addConfigurationItem(address(security));
        initDefaulFunctionsForRole();
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

    function findProducts(string memory _name) view external returns (address [] memory _product) {
        return productsByName[_name];
    }

    function getProductIds() override  view external returns (uint256[] memory _ids) {
        return ids; 
    }

    function isVerified(address _product) override view external returns (bool _verified){
        return knownByProductAddress[_product];
    }

    function getProductLog() view external returns( address[] memory _products){
        require(isSecure(productManagerRole, "getProductLog"), " product admin only ");
        return productLog;
    }   

    function createProduct(string memory _name, uint256 _price, string memory _currency, address _erc20) override external returns (address _productAddress) {
        require(isSecure(productManagerRole, "createProduct")," product admin only ");
        uint256 productId_ = productIndex++;
        ids.push(productId_);
        _productAddress = address(new OpenProduct( address(registry), productId_, _name, _price, _currency, _erc20));
        security.secureProduct(_productAddress);       
        addProductInternal(_productAddress);
        return _productAddress;
    }

    function removeProduct(address _productAddress) override external returns (bool _removed) {
        require(isSecure(productManagerRole, "removeProduct")," product admin only ");
        return removeProductInternal(_productAddress);        
    }

    function notifyChangeOfAddress() external returns (bool _recieved){
        require(isSecure(openAdminRole, "notifyChangeOfAddress")," admin only ");    
        registry                = IOpenRegister(registry.getAddress(registerCA)); // make sure this is NOT a zero address                   
        roleManager             = IOpenRoles(registry.getAddress(roleManagerCA));  
        security                = IOpenProductSecuritization(registry.getAddress(productSecurityCA));
        addConfigurationItem(address(security));  
        addConfigurationItem(address(registry));   
        addConfigurationItem(address(roleManager));         
        return true; 
    }
    // ====================================== INTERNAL =================================================

    function addProductInternal(address _productAddress) internal returns (bool _added) {
        OpenProduct product_ = OpenProduct(_productAddress);
        uint256 productId_ = product_.getId(); 
        if(!knownByProductId[productId_]){
            productsByName[product_.getName()].push(_productAddress);
            productAddressByProductId[product_.getId()] = _productAddress; 
            products.push(_productAddress);
            productLog.push(_productAddress);
            knownByProductAddress[_productAddress] = true; 
            knownByProductId[productId_] = true; 
            return true; 
        }
        return false; 
    }

    function removeProductInternal(address _productAddress) internal returns (bool _removed){
        OpenProduct product_ = OpenProduct(_productAddress);
        uint256 productId_ = product_.getId(); 
        if(knownByProductId[productId_]){
            delete productAddressByProductId[product_.getId()]; 
            delete productsByName[product_.getName()];
            products = _productAddress.remove(products);
            ids = productId_.remove(ids);
            delete knownByProductAddress[_productAddress]; 
            delete knownByProductId[productId_]; 
            return true; 
        }
        return false; 
    }

    function initDefaulFunctionsForRole() internal returns (bool _initiated){
        hasDefaultFunctionsByRole[openAdminRole] = true; 
        defaultFunctionsByRole[openAdminRole].push("notifyChangeOfAddress");

        hasDefaultFunctionsByRole[productManagerRole] = true; 
        defaultFunctionsByRole[productManagerRole].push("createProduct");
        defaultFunctionsByRole[productManagerRole].push("removeProduct");
        defaultFunctionsByRole[productManagerRole].push("getProductLog");
        return true;
    }
}