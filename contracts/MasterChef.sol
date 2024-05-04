pragma solidity 0.6.12;

import "./lib/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./QuantoSwapToken.sol";

interface IMigratorChef {
    function migrate(IERC20 token) external returns (IERC20);
}

contract MasterChef is Initializable, OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accQNSPerShare;
    }

    QuantoSwapToken public QNS;

    uint256 public devPercent = 90000;
    address public devaddr;
    uint256 public blockWithdrawDev;
    uint256 public depositedQNS;

    uint256 public QNSPerBlock;
    uint256 public BONUS_MULTIPLIER;
    IMigratorChef public migrator;
    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    uint256 public totalAllocPoint;
    uint256 public startBlock;

    event Earned(address indexed user, uint256 indexed pid, uint256 amount);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    function initialize(
        QuantoSwapToken _QNS,
        address _devaddr,
        uint256 _QNSPerBlock,
        uint256 _startBlock
    ) public initializer {
        QNS = _QNS;
        devaddr = _devaddr;
        QNSPerBlock = _QNSPerBlock;
        startBlock = _startBlock;
        blockWithdrawDev = _startBlock;

        poolInfo.push(PoolInfo({
            lpToken: _QNS,
            allocPoint: 1200,
            lastRewardBlock: startBlock,
            accQNSPerShare: 0
        }));

        totalAllocPoint = 1200;
        BONUS_MULTIPLIER = 1;

        __Ownable_init();
    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function withdrawDevFee() public{
        require(blockWithdrawDev < block.number, 'wait for new block');
        uint256 multiplier = getMultiplier(blockWithdrawDev, block.number);
        uint256 QNSReward = multiplier.mul(QNSPerBlock);
        QNS.mint(devaddr, QNSReward.mul(devPercent).div(1000000));
        blockWithdrawDev = block.number;
    }

    function newDevAddress(address _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    function newQNSPerBlock(uint256 _QNSPerBlock) public onlyOwner {
        QNSPerBlock = _QNSPerBlock;
    }

    function add( uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accQNSPerShare: 0
            })
        );
    }

    function set( uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        pool.lpToken = newLpToken;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function pendingQNS(uint256 _pid, address _user) external view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accQNSPerShare = pool.accQNSPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (_pid == 0){
            lpSupply = depositedQNS;
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 QNSReward = multiplier.mul(QNSPerBlock).mul(pool.allocPoint).div(totalAllocPoint).mul(910).div(1000);
            accQNSPerShare = accQNSPerShare.add(QNSReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accQNSPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (_pid == 0){
            lpSupply = depositedQNS;
        }
        if (lpSupply <= 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 QNSReward = multiplier.mul(QNSPerBlock).mul(pool.allocPoint).div(totalAllocPoint).mul(910).div(1000);
        QNS.mint(address(this), QNSReward);
        pool.accQNSPerShare = pool.accQNSPerShare.add(QNSReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        require (_pid != 0, 'deposit QNS by staking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accQNSPerShare).div(1e12).sub(user.rewardDebt);
            safeQNSTransfer(msg.sender, pending);
            emit Earned(msg.sender, _pid, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accQNSPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        require (_pid != 0, 'withdraw QNS by unstaking');
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accQNSPerShare).div(1e12).sub(user.rewardDebt);
        safeQNSTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accQNSPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
        emit Earned(msg.sender, _pid, pending);
    }

    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accQNSPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeQNSTransfer(msg.sender, pending);
                emit Earned(msg.sender, 0, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
            depositedQNS = depositedQNS.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accQNSPerShare).div(1e12);
        emit Deposit(msg.sender, 0, _amount);
    }

    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accQNSPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeQNSTransfer(msg.sender, pending);
            emit Earned(msg.sender, 0, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            depositedQNS = depositedQNS.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accQNSPerShare).div(1e12);
        emit Withdraw(msg.sender, 0, _amount);
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        if (_pid == 0){
            depositedQNS = depositedQNS.sub(user.amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function safeQNSTransfer(address _to, uint256 _amount) internal {
        uint256 QNSBal = QNS.balanceOf(address(this));
        if (_amount > QNSBal) {
            QNS.transfer(_to, QNSBal);
        } else {
            QNS.transfer(_to, _amount);
        }
    }
}
