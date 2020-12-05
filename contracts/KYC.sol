pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

contract kyc {
    address admin;

    /*
    Struct for a customer
     */
    struct Customer {
        string userName;
        string data_hash;
        uint8 upvotes;
        uint256 rating;
        address bank;
        string password;
        address lastChanged;
        uint256 timestamp;
    }

    /*
    Struct for a Bank's votes mapping
     */
    struct BankVotes {
        address votedBank;
        bool hasVoted;
        uint256 timestamp;
    }

    /*struct for a Bank */
    struct Bank {
        address ethAddress; //unique
        string bankName;
        string regNumber; //unique
        uint256 rating;
        uint256 kycCount;
        uint256 upvotes;
        mapping(address => BankVotes) bankVote;
    }

    /*new struct to return bank, as original bank has nested mapping*/
    struct BankReturn {
        address ethAddress;
        string bankName;
        string regNumber;
        uint256 rating;
        uint256 kycCount;
        uint256 upvotes;
    }

    /*
    Struct for a KYC Request
     */
    struct KYCRequest {
        string userName;
        string data_hash; //unique
        address bank;
        bool isAllowed;
    }

    /*
    Mapping a customer's username to the Customer struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(string => Customer) public customers;
    string[] customerNames;

    /*
    Mapping a bank's address to the Bank Struct
    We also keep an array of all keys of the mapping to be able to loop through them when required.
     */
    mapping(address => Bank) public banks;
    address[] bankAddresses;

    /*
    Mapping a customer's Data Hash to KYC request captured for that customer.
    This mapping is used to keep track of every kycRequest initiated for every customer by a bank.
     */
    mapping(string => KYCRequest) public kycRequests;
    string[] customerDataList;

    /*
    Mapping a customer's user name with a bank's address
    This mapping is used to keep track of every upvote given by a bank to a customer
     */
    mapping(string => mapping(address => uint256)) upvotes;

    /**
     * Constructor of the contract.
     * We save the contract's admin as the account which deployed this contract.
     */
    constructor() public {
        admin = msg.sender;
    }

    // Functions for KYC Requests
    // Owners  - banks
    //event Check(uint256 check, uint256 rating, bool lol);
    function addKycRequest(string memory _userName, string memory _customerData)
        public
        returns (uint8)
    {
        // Check that the user's KYC has not been done before, the Bank is a valid bank and it is allowed to perform KYC.
        require(
            kycRequests[_customerData].bank == address(0),
            "This user already has a KYC request with same data in process."
        );

        uint256 check = bankAddresses.length / uint256(2); //bankAddresses/2 gives half of banks votes, so if rating is more than that, it means its > 0.5
        /*check for rating of bank is Allowed validation*/
        //emit Check(check, banks[msg.sender].rating, banks[msg.sender].rating < check);
        if (banks[msg.sender].rating < check) {
            kycRequests[_customerData].isAllowed = false;
        } else {
            kycRequests[_customerData].isAllowed = true;
        }
        kycRequests[_customerData].data_hash = _customerData;
        kycRequests[_customerData].userName = _userName;
        kycRequests[_customerData].bank = msg.sender;
        customerDataList.push(_customerData);
        return 1;
    }

    function removeKYCRequest(
        string memory _userName,
        string memory _customerData
    ) public returns (uint8) {
        //improve this function
        uint8 i = 0;
        for (uint256 i = 0; i < customerDataList.length; i++) {
            if (
                stringsEquals(
                    kycRequests[customerDataList[i]].userName,
                    _userName
                )
            ) {
                delete kycRequests[_customerData];
                for (uint256 j = i + 1; j < customerDataList.length; j++) {
                    customerDataList[j - 1] = customerDataList[j];
                }
                customerDataList.length--;
                i = 1;
            }
        }
        return i; // 0 is returned if no request with the input username is found.
    }

    /*Debugging purposes*/
    function returnAdmin() public view returns (address) {
        return admin;
    }

    /*Customer related function */
    /*Owner - Bank */
    function addCustomer(string memory _userName, string memory _customerData)
        public
        returns (uint8)
    {
        if (stringsEquals(customers[_userName].data_hash, _customerData)) {
            return 0;
        }
        uint256 flag = 0;
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == msg.sender) {
                flag = 1;
            }
        }
        if (flag == 0) {
            return 0;
        }
        require(
            kycRequests[_customerData].isAllowed == true,
            "KYC details not verified yet"
        );
        if (kycRequests[_customerData].isAllowed) {
            customers[_userName].userName = _userName;
            customers[_userName].data_hash = _customerData;
            customers[_userName].bank = msg.sender;
            customers[_userName].upvotes = 0;
            customers[_userName].password = "0";
            customers[_userName].lastChanged = msg.sender;
            customers[_userName].timestamp = now;
            customerNames.push(_userName);
            return 1;
        } else {
            return 0;
        }
    }

    function removeCustomer(string memory _userName) public returns (uint8) {
        uint256 flag = 0;
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == msg.sender) {
                flag = 1;
            }
        }
        if (flag == 0) {
            return 0;
        }
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], _userName)) {
                delete customers[_userName];
                for (uint256 j = i + 1; j < customerNames.length; j++) {
                    customerNames[j - 1] = customerNames[j];
                }
                customerNames.length--;
                return 1;
            }
        }
        return 0;
    }

    function modifyCustomer(
        string memory _userName,
        string memory _newcustomerData
    ) public returns (uint8) {
        uint256 flag = 0;
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == msg.sender) {
                flag = 1;
            }
        }
        if (flag == 0) {
            return 0;
        }
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], _userName)) {
                customers[_userName].upvotes = 0;
                customers[_userName].data_hash = _newcustomerData;
                customers[_userName].lastChanged = msg.sender;
                for (uint256 k = 0; k < customerNames.length; k++) {
                    if (stringsEquals(customerNames[k], _userName)) {
                        delete customers[_userName];
                        for (uint256 j = k + 1; j < customerNames.length; j++) {
                            customerNames[j - 1] = customerNames[j];
                        }
                        customerNames.length--;
                        return 1;
                    }
                }
                return 1;
            }
        }
        return 0;
    }

    function getCustomerRating(string memory _userName)
        public
        view
        returns (uint256)
    {
        uint256 flag = 0;
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == msg.sender) {
                flag = 1;
            }
        }
        if (flag == 0) {
            return 0;
        }
        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], _userName)) {
                return customers[_userName].rating;
            }
        }
        return 0;
    }

    function viewCustomer(string memory _userName, string memory _password)
        public
        view
        returns (string memory)
    {
        if (stringsEquals(customers[_userName].password, _password)) {
            return (customers[_userName].data_hash);
        } else if (stringsEquals(customers[_userName].password, "0")) {
            return (customers[_userName].data_hash);
        } else {
            return "0";
        }
    }

    function retrieveHistoryOf(string memory _userName)
        public
        view
        returns (
            address,
            string memory,
            string memory
        )
    {
        return (
            banks[customers[_userName].lastChanged].ethAddress,
            banks[customers[_userName].lastChanged].bankName,
            banks[customers[_userName].lastChanged].regNumber
        );
    }

    function setCustomerPassword(
        string memory _userName,
        string memory _password
    ) public returns (uint256) {
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (banks[bankAddresses[i]].ethAddress == msg.sender) {
                uint256 check = (bankAddresses.length / uint256(2));
                require(banks[bankAddresses[i]].rating >= check,"Bank should have rating more than 0.5");
                customers[_userName].password = _password;
                customers[_userName].lastChanged = msg.sender;
            }
        }
    }

    /*Bank Related Function  */
    /*Owner - Banks*/

    function addUpvoteTo(address _bankAddr) public payable returns (uint256) {
        // you are stuck here rethink
        uint256 flag = 0;
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == msg.sender) {
                flag = 1;
            }
        }
        if (flag == 0) {
            return 0;
        }
        if (_bankAddr == msg.sender) {
            return 0;
        }
        if (banks[_bankAddr].bankVote[msg.sender].hasVoted == true) {
            return 0;
        }
        banks[_bankAddr].upvotes++;
        banks[_bankAddr].rating = banks[_bankAddr].upvotes;
        banks[_bankAddr].bankVote[msg.sender].hasVoted = true;
        banks[_bankAddr].bankVote[msg.sender].timestamp = now;
        return 1;
    }

    function getBankRating(address _address) public view returns (uint) {
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == _address) {
                return banks[_address].rating;
            }
        }
        return 0;
    }

    function getBankDetails(address _bankAddr)
        public
        view
        returns (BankReturn[] memory)
    {
        BankReturn[] memory toBeReturnedBankDetails = new BankReturn[](
            bankAddresses.length
        );
        uint256 x = 0; //temp variable
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (banks[bankAddresses[i]].ethAddress == _bankAddr) {
                toBeReturnedBankDetails[x++] = BankReturn({
                    ethAddress: banks[bankAddresses[i]].ethAddress,
                    bankName: banks[bankAddresses[i]].bankName,
                    regNumber: banks[bankAddresses[i]].regNumber,
                    rating: banks[bankAddresses[i]].rating,
                    kycCount: banks[bankAddresses[i]].kycCount,
                    upvotes: banks[bankAddresses[i]].upvotes
                });
            }
        }
        //toBeReturnedBankDetails.length--;
        return toBeReturnedBankDetails;
    }

    function getBankRequests(address _bankAddr)
        public
        returns (KYCRequest[] memory)
    {
        // cant declare as view because we are modifying bankRequests acc to solc
        KYCRequest[] memory toBeReturnedBanks = new KYCRequest[](
            customerDataList.length
        );
        uint256 x = 0; //temp var
        for (uint256 i = 0; i < customerDataList.length; i++) {
            if (
                (kycRequests[customerDataList[i]].bank == _bankAddr) &&
                (kycRequests[customerDataList[i]].isAllowed == true)
            ) {
                toBeReturnedBanks[x++] = KYCRequest({
                    data_hash: kycRequests[customerDataList[i]].data_hash,
                    userName: kycRequests[customerDataList[i]].userName,
                    bank: kycRequests[customerDataList[i]].bank,
                    isAllowed: kycRequests[customerDataList[i]].isAllowed
                });
            }
        }
        banks[_bankAddr].kycCount = toBeReturnedBanks.length; // check this unnecessary logic later
        return toBeReturnedBanks;
    }

    function Upvote(string memory _userName) public returns (uint8) {
        uint256 flag = 0;
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == msg.sender) {
                flag = 1;
            }
        }
        if (flag == 0) {
            return 0;
        }

        for (uint256 i = 0; i < customerNames.length; i++) {
            if (stringsEquals(customerNames[i], _userName)) {
                //if(!upvotes[_userName][msg.sender]){
                customers[_userName].upvotes++;
                customers[_userName].rating = customers[_userName].upvotes;
                upvotes[_userName][msg.sender] = now; //storing the timestamp when vote was casted, not required though, additional
                customers[_userName].lastChanged = msg.sender;
                return 1;
                //}
            }
        }
        return 0;
    }

    /*Admin Functions */
    /*Owners - Admin*/
    function addbank(
        string memory _bankName,
        address _bankAddr,
        string memory _bankRegNo
    ) public returns (uint256) {
        require(msg.sender == admin, "Only admins can add bank");

        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == _bankAddr) {
                return 0;
            }
        }
        banks[_bankAddr].ethAddress = _bankAddr;
        banks[_bankAddr].bankName = _bankName;
        banks[_bankAddr].regNumber = _bankRegNo;
        banks[_bankAddr].rating = 0;
        banks[_bankAddr].kycCount = 0;
        banks[_bankAddr].upvotes = 0;
        bankAddresses.push(_bankAddr);
        return 1;
    }

    function deleteBank(address _bankAddr) public returns (uint8) {
        require(msg.sender == admin, "Only admins can add bank");
        for (uint256 i = 0; i < bankAddresses.length; i++) {
            if (bankAddresses[i] == _bankAddr) {
                delete banks[_bankAddr];
                for (uint256 j = i + 1; j < bankAddresses.length; j++) {
                    bankAddresses[j - 1] = bankAddresses[j];
                }
                bankAddresses.length--;
                return 1;
            }
        }
        return 0;
    }

    /*String Compare Function */
    function stringsEquals(string storage _a, string memory _b)
        internal
        view
        returns (bool)
    {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length) return false;
        // @todo unroll this loop
        for (uint256 i = 0; i < a.length; i++) {
            if (a[i] != b[i]) return false;
        }
        return true;
    }
}
