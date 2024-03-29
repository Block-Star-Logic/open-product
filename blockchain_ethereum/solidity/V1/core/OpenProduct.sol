// SPDX-License-Identifier: APACHE-2.0
pragma solidity ^0.8.15;


import "https://github.com/Block-Star-Logic/open-roles/blob/732f4f476d87bece7e53bd0873076771e90da7d5/blockchain_ethereum/solidity/v2/contracts/core/OpenRolesSecureDerivative.sol";

import "https://github.com/Block-Star-Logic/open-register/blob/7b680903d8bb0443b9626a137e30a4d6bb1f6e43/blockchain_ethereum/solidity/V1/interfaces/IOpenRegister.sol";

import "../interfaces/IOpenProduct.sol";



contract OpenProduct is OpenRolesSecureDerivative, IOpenProduct { 

    using LOpenUtilities for string; 

    IOpenRegister registry; 
    
    mapping(string=>address)    featureADDRESSValueByFeatureName; 
    mapping(string=>string)     featureSTRValueByFeatureName; 
    mapping(string=>uint256)    featureUINTValueByFeatureName; 
    mapping(string=>bool)       hasFeatureByFeatureName; 
    mapping(string=>string)     typeByFeatureName; 
    
    mapping(string=>address)    featureManagerAddressByFeature; 
    mapping(string=>uint256)    featureFeeByFeature; 

    string dappProductManagerRole       = "DAPP_PRODUCT_MANAGER_ROLE";
    string productManagerRole           = "PRODUCT_MANAGER_ROLE";
    string openAdminRole                = "RESERVED_OPEN_ADMIN_ROLE";

    string registerCA                   = "RESERVED_OPEN_REGISTER_CORE";
    string roleManagerCA                = "RESERVED_OPEN_ROLES_CORE";

    string priceKey                     = "PRODUCT_PRICE";

    string name; 
    uint256 id; 

    struct Price {
        string currency; 
        uint256 value; 
        address erc20; 
    }

    Price price; 

    constructor(address _registryAddress, uint256 _id, string memory _name, uint256 _priceValue, string memory _priceCurrency, address _priceContract) {
        registry = IOpenRegister(_registryAddress);
        setRoleManager(registry.getAddress(roleManagerCA));       
        addConfigurationItem(_registryAddress);
        addConfigurationItem(address(roleManager));      

        id = _id;        
        name = _name; 
        setPriceInternal(_priceValue, _priceCurrency, _priceContract);                
    }

    function getId() override view external returns (uint _id){
        return id;
    }

    function getName() override view external returns (string memory _name){
        return name;
    }

    function getPrice() override view external returns (uint256 _price){
        return (price.value);
    }

    function getCurrency() override view external returns (string memory _currency) {
        return price.currency; 
    }

    function getErc20() override view external returns (address _erc20) {
        return price.erc20; 
    }

    function getFeatureFee(string memory _feature) override view external returns (uint256 _fee){
        return featureFeeByFeature[_feature];
    }

    function getFeatureUINTValue(string memory _featureName) override view external returns (uint256 _value){
        return featureUINTValueByFeatureName[_featureName];
    }

    function getFeatureSTRValue(string memory _featureName) override view external returns (string memory _value){
        return featureSTRValueByFeatureName[_featureName];
    }

    function getFeatureADDRESSValue(string memory _featureName) override view external returns (address _value){
        return featureADDRESSValueByFeatureName[_featureName];
    }

    function hasFeature(string memory _featureName) override view external returns (bool _hasFeature){
        return hasFeatureByFeatureName[_featureName];
    }

    function getFeatureManager(string memory _feature) override view external returns (address _featureManager){
        return featureManagerAddressByFeature[_feature];
    }

    function setFeatureUINTValue(string memory _featureName, uint256 _featureValue) external returns(bool _set) {        
        require(isSecure(productManagerRole, "setFeatureUINTValue") ||
                isSecure(dappProductManagerRole,"setFeatureUINTValue" )," product manager only ");
        require(!hasFeatureByFeatureName[_featureName], string(" known feature of type ").append(typeByFeatureName[_featureName]));       
        return setFeatureUINTValueInternal(_featureName, _featureValue);
    }

    function setFeatureSTRValue(string memory _featureName, string memory _featureValue) external returns(bool _set) {
        require(isSecure(productManagerRole, "setFeatureSTRValue") ||
                isSecure(dappProductManagerRole,"setFeatureSTRValue" )," product manager only ");
        require(!hasFeatureByFeatureName[_featureName], string(" known feature of type ").append(typeByFeatureName[_featureName]));        
        return setFeatureSTRValueInternal(_featureName, _featureValue);
    }

    function setFeatureADDRESSValue(string memory _featureName, address _featureValue) external returns(bool _set) {
        require(isSecure(productManagerRole, "setFeatureADDRESSValue") ||
                isSecure(dappProductManagerRole,"setFeatureADDRESSValue" )," product manager only ");
        require(!hasFeatureByFeatureName[_featureName], string(" known feature of type ").append(typeByFeatureName[_featureName]));        
        return setFeatureADDRESSValueInternal(_featureName, _featureValue);
    }

    function removeFeatureValue(string memory _featureName) external returns (bool _removed) {
        require(isSecure(productManagerRole, "removeFeatureValue") ||
                isSecure(dappProductManagerRole,"removeFeatureValue" )," product manager only ");
        string memory featureType_ = typeByFeatureName[_featureName]; 
        if(featureType_.isEqual("STR")) {
            delete featureSTRValueByFeatureName[_featureName];
        }
        if(featureType_.isEqual("UINT")) {
            delete featureUINTValueByFeatureName[_featureName];

        }
        if(featureType_.isEqual("ADDRESS")) {
            delete featureADDRESSValueByFeatureName[_featureName];
        }
        delete hasFeatureByFeatureName[_featureName];
        return true; 
    }

    function setPrice (uint256 _priceValue, string memory _priceCurrency, address _priceContract) external returns (bool _set) {
        require(isSecure(productManagerRole, "setPrice") ||
                isSecure(dappProductManagerRole,"setPrice" )," product manager only ");
        return setPriceInternal(_priceValue, _priceCurrency, _priceContract);        
    }

    function setFeatureFee(string memory _feature, uint256 _fee) external returns (bool _set){
        require(isSecure(productManagerRole, "setFeatureFee") ||
                isSecure(dappProductManagerRole,"setFeatureFee" )," product manager only ");
        featureFeeByFeature[_feature] = _fee; 
        return true; 
    }

    function addFeatureManager(string memory _feature, address featureManager) external returns (bool _added) {        
        require(isSecure(productManagerRole, "addFeatureManager") ||
                isSecure(dappProductManagerRole,"addFeatureManager" )," product manager only ");
        featureManagerAddressByFeature[_feature] = featureManager; 
        return true; 
    }

    function removeFeatureManager(string memory _feature) external returns (bool _removed){        
        require(isSecure(productManagerRole, "removeFeatureManager") ||
                isSecure(dappProductManagerRole,"removeFeatureManager" )," product manager only ");
        delete featureManagerAddressByFeature[_feature];
        return true; 
    }

    function notifyChangeOfAddress() external returns (bool _recieved){
        require(isSecure(openAdminRole, "notifyChangeOfAddress")," admin only ");    
        registry                = IOpenRegister(registry.getAddress(registerCA)); // make sure this is NOT a zero address                   
        roleManager             = IOpenRoles(registry.getAddress(roleManagerCA));    
        addConfigurationItem(address(registry));   
        addConfigurationItem(address(roleManager));         
        return true; 
    }

    //=============================================== INTERNAL ==========================================

    function setPriceInternal(uint256 _priceValue, string memory _priceCurrency, address _priceContract) internal returns (bool _set) {
            //@todo add product admin feature 
        price = Price({
                currency : _priceCurrency,
                value : _priceValue, 
                erc20 : _priceContract
        });
        setFeatureUINTValueInternal(priceKey, _priceValue);    
        return true; 
    }

    function setFeatureUINTValueInternal(string memory _name, uint256 _value)  internal returns (bool _set) {
        featureUINTValueByFeatureName[_name] = _value;
        hasFeatureByFeatureName[_name] = true;
        typeByFeatureName[_name] = "UINT";
        return true; 
    }

    function setFeatureSTRValueInternal(string memory _name, string memory _value)  internal returns (bool _set) {
        featureSTRValueByFeatureName[_name] = _value;
        hasFeatureByFeatureName[_name] = true;
        typeByFeatureName[_name] = "STR";
        return true; 
    }

    function setFeatureADDRESSValueInternal(string memory _name, address _value)  internal returns (bool _set) {
        featureADDRESSValueByFeatureName[_name] = _value;
        hasFeatureByFeatureName[_name] = true;
        typeByFeatureName[_name] = "ADDRESS";
        return true; 
    }

}