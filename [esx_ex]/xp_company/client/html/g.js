let loading = null
let  PERMISSION_SALARY = 1
let  PERMISSION_Hire = 2
let  PERMISSION_Fire = 3
let  PERMISSION_PROJECT = 4
let  PERMISSION_Rule = 5
 
let Skill_Program = 'program'
let Skill_Design = 'design'
let Skill_Test = 'test'
let Skill_Resource = 'resource'
let Skill_Project = 'project' 

let Time_AutoAgree = 60
/* function cegPermissons(){
	return [{
						id = PERMISSION_Hire,
						title = '招聘员工'
					},{
						id = PERMISSION_Fire,
						title = '解雇员工'
					}]
} */
 
 
function sendMessageToClient(vueInstance, data, cb, showLoading) {

	if (showLoading && loading == null) {

		loading = vueInstance.$loading({
			lock: true,
			text: getLocal('wait'),
			spinner: 'el-icon-loading',
			background: 'rgba(0, 0, 0, 0.7)'
		});
	}

	$.post('http://xp_company/htmlEvent', JSON.stringify(data), function(resultData, status, xhr) {
		if (showLoading && loading != null) {
			loading.close()
			loading = null
		}
		//console.log("request ->\n" + JSON.stringify(data) + "\n response ->\n" + resultData)
		cb(JSON.parse(resultData))
	})
}

function notification(instance,title, type, message) {
			instance.$notify({
				title: title,
				message: message?message:(type === 'success'?getLocal('doSucess'):getLocal('doFail')),
				type: type
			});
		}
		
function messageConfirm(instance,msg,callback){
	instance.$confirm(msg, '', {
	          confirmButtonText: getLocal('confirm'),
	          cancelButtonText: getLocal('cancel'),
	          type: 'warning'
	        }).then(() => {
	          callback(true)
	        }).catch(() => {
	           callback(false)      
	        });
}		

function getChairById(id, departments) {
	for (let department of departments) {
		if (department.id == id) {
			return department
		}
	}
}

function getDepartmentById(id, chairs) {
	for (let chair of chairs) {
		if (chair.id == id) {
			return chair
		}
	}
}

/* function getTimeFromMills(mills) {
			let newDate = new Date(mills);
			return newDate.getFullYear() + "年" + (newDate.getMonth() + 1) + "月" + newDate.getDate() + "日" +
				newDate.getHours() + "时" + newDate.getMinutes() + "分";
		} */
function getCCmTime(strTime){
	//console.log(strTime,typeof(strTime))
	let time = typeof(strTime) === 'string'?JSON.parse(strTime):strTime
	return time.year + getLocal('year') + time.month + getLocal('month')+ time.day + getLocal('day')+ (time.segment?time.segment:0) + getLocal('segment')
}
function getMyCompany(instance,callback,showloading) {
	
	sendMessageToClient(instance,{
		action: "getMyCompany"
	}, function(company){
		for(let department of company.departments)
		{
			
			department.createTime_ = getCCmTime(department.createTime)
			for (let department2 of company.departments) {
				if (department2.id == department.upDepartmentId) {
					department.upDepartmentName = department2.name
					break
				}
			}
			
			if(department.leaderId){
				for(let staff of company.staffs){
					if(staff.id == department.leaderId)
					{
						department.leaderName = staff.name
						break
					}
					
				}
			}
			
			
		}
		
		for(let staff of company.staffs)
		{
			staff.createTime_ = getCCmTime(staff.createTime)
			staff.sex_ = staff.sex == 1 ? getLocal('man') : getLocal('woman')
			
			//staff.permissons = JSON.parse(staff.permissons)
		
			staff.skills_ = staff.skills && typeof(staff.skills) === 'string'?JSON.parse(staff.skills):staff.skills
			
			staff.ability = 0
			for(let skill of staff.skills_){
				staff.ability += skill.value
			}
			
			
			
			/* let permissons = []
			for(let p of staff.permissons)
			{
				console.log('-->p '+p)
				permissons.push(Number(p))
			}
			staff.permissons = permissons */
		}
		
		for(let project of company.projects)
		{
			project.createTime_ = getCCmTime(project.createTime)
			project.endTime_ = getCCmTime(project.endTime)
			
			let taskTmp = typeof(company.tasks) === 'string'?JSON.parse(company.tasks):company.tasks
			
			
		}
		
		
		
		//console.log("company "+JSON.stringify(company))
		
		callback(company)
	},showloading)
}

function getDepartments(instance,comId,callback,showloading) {
	
	sendMessageToClient(instance,{
		action: "getComDepartments",
		comId: comId
	}, callback,showloading)
}

function getStaffs(instance,comId,callback,showloading) {
	
	sendMessageToClient(instance,{
		action: "getCompanyStaffs",
		comId: comId
	}, callback,showloading)
}



function getPermissions(instance,callback,showloading) {
	sendMessageToClient(instance,{action: "getPermissions"},callback,showloading )
}

function goMainPage(){
	window.location.href = "index.html?visible=1"
}

function isStaffHavePermisson(staff,permisson){
	
	if(!staff || !staff.permissons){
		return false
	}
	
	for(let perm of staff.permissons){
		if(perm == permisson){
			return true
		}
	}
	
	return false
	
}

function isStaffHaveSkill(staff,skill){
	
	if(!staff || !staff.skills){
		return false
	}
	
	for(let ski of staff.skills){
		if(ski.id == skill){
			return true
		}
	}
	
	return false
	
}

function getStaffById(staffs,id){
	for(let staff of staffs){
		if(staff.id == id){
			return staff
		}
	}
	return null
}

function getStaffBySeatId(staffs,seatId){
	
	for(let staff of staffs){
		if(staff.seatId == seatId){
			return staff
		}
	}
	return null
}

function isDepartmentUnder(departments,dpRoot,dpJuge)
{
	let dps = getDepartmentChilds(departments,dpRoot)
	if(dps.length == 0)
	{
		if(dpRoot.id == dpJuge.id)
		{
			return true
		}
	}
	else
	{
		for(let dp of dps)
		{
			if(dp.id == dpJuge.id)
			{
				return true
			}
			return isDepartmentUnder(departments,dp,dpJuge)
		}
	}
	
	return false
	
	
}

function flatDepartmentToTree(departments,departmentRoot)
{

	
	departmentRoot.children = getDepartmentChilds(departments,departmentRoot)
	
	departmentRoot.children.sort(function(a,b){
			  if (a.name < b.name) {
			     return -1;
			   }
			   if (a.name > b.name) {
			     return 1;
			   }
			   return 0;
		}) 
	
	if(departmentRoot.children.length != 0)
	{
		for(let dp of departmentRoot.children)
		{
			flatDepartmentToTree(departments,dp)
		}
	}
	
	
}

function flatArrayToTree2(departments,departmentRoot,staffRoot,allstaffs) {

  let childs = getDepartmentChilds(departments,departmentRoot)
  departmentRoot.children = childs
  let staffs = []
  for(let staff of allstaffs)
  {
	  
	  for(let depart of departments)
	  {
		  if(depart.upDepartmentId == departmentRoot.id && staff.id == depart.leaderId)
		  {
			  staffs.push(staff)
			
			  
		  }
		  
		  
	  }
	  
	 
  }
  
  
  
  staffRoot.staffs = staffs
  
  
  staffRoot.groupName = departmentRoot.name
  //result.push(departmentRoot)
  for(let department of childs)
  {
	  
	  let leaderStaff = null
	    for(let staff of allstaffs)
	    {
	    	  if(staff.id == department.leaderId)
	    	  {
	    		  leaderStaff = staff
				  break
	    	  }
	    }
	  if(leaderStaff)
	  {
		   flatArrayToTree2(departments,department,leaderStaff,allstaffs)
	  }
	 
  }
}


function flatArrayToTree3(departmentRoot,allstaffs) {

if(departmentRoot.children.length != 0)
{
	for(let dp of departmentRoot.children)
	{
		 flatArrayToTree3(dp,allstaffs)
	}
	
	//但是同时获取手下的员工
	let subStaffs = []
	for(let staff of allstaffs)
	{
		  
		  if(staff.departmentId == departmentRoot.id && !staff.playerId)
		  {
		  	if(staff.id == departmentRoot.leaderId)
			{
				staff.departmentGroup = getLocal('dpleader')
				departmentRoot.model = staff.model
			}
			else
			{
				staff.departmentGroup = ''
			}
			subStaffs.push(JSON.parse(JSON.stringify(staff)))
		  				
		  				  
		  }
		  else if(staff.id == departmentRoot.leaderId)
			{
				
				departmentRoot.model = staff.model
			}
	
	}
	
	 subStaffs.sort(function(a,b){
			  
			  if (a.departmentGroup < b.departmentGroup) {
			     return 1;
			   }
			   if (a.departmentGroup > b.departmentGroup) {
			     return -1;
			   }
			   return 0;
		}) 
		
	departmentRoot.children = subStaffs.concat(departmentRoot.children)	
	
	
	departmentRoot.departmentGroup = departmentRoot.name + " ["+departmentRoot.children.length+"]"
	
}
else
{
	departmentRoot.children = []
	let subStaffs = []
	for(let staff of allstaffs)
	{
		  
		  if(staff.departmentId == departmentRoot.id)
		  {
		  	
			
			if(staff.id == departmentRoot.leaderId)
			{
				staff.departmentGroup = getLocal('dpleader')
				departmentRoot.model = staff.model
			}
			else
			{
				staff.departmentGroup = ''
			}
			subStaffs.push(JSON.parse(JSON.stringify(staff)))
		  				
		  				  
		  }
		  else if(staff.id == departmentRoot.leaderId)
			{
				
				departmentRoot.model = staff.model
			}

	}
	
	if(subStaffs.length == 0)
	{
		for(let staff of allstaffs)
		{
			  
			  if(staff.id == departmentRoot.leaderId)
			  {
			  	departmentRoot.model = staff.model
				break
			  }
		
		}
	}
	else
	{
		subStaffs.sort(function(a,b){
					  
					  if (a.departmentGroup < b.departmentGroup) {
					     return 1;
					   }
					   if (a.departmentGroup > b.departmentGroup) {
					     return -1;
					   }
					   return 0;
				}) 
	}
	
	departmentRoot.children = subStaffs.concat(departmentRoot.children)	
	
	departmentRoot.departmentGroup = departmentRoot.name + " ["+departmentRoot.children.length+"]"
}

}

function getDepartmentChilds(departments,departmentRoot)
{
	let result = []
	for(let department of departments)
	{
		if(department.upDepartmentId == departmentRoot.id)
		{
			result.push(department)
		}
	}
	
	return result
}

function getStaffsOfLeader(treeStaff,departments,allstaffs)
{

	if(!treeStaff.staffs)
	{
		treeStaff.staffs = []
	}

	if(treeStaff.staffs.length != 0)
	{
		
		for(let staff of treeStaff.staffs)
		{
			//console.log('展开下属 '+staff.name)
			getStaffsOfLeader(staff,departments,allstaffs)
		}
		
		//但是同时也要拿到这个treeStaff的手下
		let staffsSub = []
				//console.log('获取下属'+treeStaff.name)
		for(let staffSub of allstaffs)
		{
				   for(let department of departments)
				   {
					   if(staffSub.departmentId == department.id && staffSub.id != treeStaff.id && department.leaderId == treeStaff.id)
					   {
						   let isCon = false
						   for(let st of treeStaff.staffs)
						   {
							   if(st.id == staffSub.id)
							   {
								   isCon = true
								   break
							   }
						   }
						   if(!isCon)
						   {
							   treeStaff.staffs.push(JSON.parse(JSON.stringify(staffSub)))
						   }
					   }
				   }
		}
		treeStaff.departmentGroup = treeStaff.groupName + " ["+treeStaff.staffs.length+"]"
		
		//treeStaff.staffs = staffsSub
		
	}
	else
	{
		let staffsSub = []
		//console.log('获取下属 '+treeStaff.name)
	   for(let staffSub of allstaffs)
	   {
		   for(let department of departments)
		   {
			   //console.log("判断部门 "+department.name)
			   //console.log('判断下属 '+treeStaff.name+','+staffSub.departmentId+','+department.id+','+department.leaderId+','+staffSub.name+","+treeStaff.id+','+staffSub.id)
			   if(staffSub.departmentId == department.id && staffSub.id != treeStaff.id && department.leaderId === treeStaff.id)
			   {
				   //console.log('添加下属 '+treeStaff.name +' -> '+staffSub.name)
				   let tmpStaff = JSON.parse(JSON.stringify(staffSub))
				   tmpStaff.departmentGroup = ''
				   
				   staffsSub.push(tmpStaff)
			   }
		   }
	   }
	   //console.log('得到下属个数 '+treeStaff.name +' '+staffsSub.length)
	   treeStaff.departmentGroup = treeStaff.groupName + " ["+staffsSub.length+"]"
	   treeStaff.staffs = staffsSub
		
	}
	
}



let language = 'zh'

let local = {
	'zh-sucess':'成功',
	'zh-name':'姓名',
	'zh-index-group':'组织架构',
	'zh-index-task':'日常事务',
	'zh-index-buiness':'运营管理',
	'zh-index-regiest':'注册公司',
	'zh-index-exithtml':'退出页面',
	
	'zh-index-staffhire-getpost':'收到一份简历',
	'zh-index-reqpullsalary':'提薪申请',
	'zh-index-reqtmpoffwork':'请假申请',
	
	'zh-tip':'提示',
	'zh-department':'部门',
	'zh-post':'岗位',
	'zh-salary':'薪资',
	'zh-seat':'座位',
	'zh-honest':'态度',
	'zh-ability':'能力',
	'zh-reject':'拒绝',
	'zh-hire':'雇佣',
	
	'zh-customrequst':'客户项目需求',
	'zh-named':'名称',
	'zh-payback':'报酬',
	'zh-endtime':'截止日期',
	'zh-createprojtime':'立项日期',
	'zh-recive':'接受',
	
	'zh-salaryconfirm':'公司账目',
	'zh-money':'金额',
	'zh-detail':'明细',
	'zh-delay':'延后',
	
	
	'zh-projectfire':'项目赔偿',
	'zh-choiceadmin':'请选择一个项目管理人员',
	'zh-msgchangeproadmin':'确定变更项目管理人员吗',
	
	'zh-inputcmpname':'请输入公司名称',
	'zh-inputyourname':'请输入您的名字',
	
	'zh-confirm':'确认',
	'zh-cancel':'取消',
	
	'zh-dpmanage':'部门管理',
	'zh-adddp':'添加部门',
	'zh-dpname':'部门名称',
	'zh-dpup':'上级部门',
	'zh-dpleader':'部门主管',
	'zh-createtime':'创建日期',
	'zh-msgupdp':'请选择一个上级部门',
	'zh-msgdpleader':'请选择一个部门领导',
	
	'zh-staffmanage':'员工管理',
	'zh-stafftotal':'员工总数',
	'zh-sex':'性别',
	'zh-staffjointime':'入职日期',
	
	'zh-comnotification':'消息通知',
	'zh-notifytype_offwork':'离职',
	
	'zh-staffedit':'员工编辑',
	'zh-headicon':'头像',
	'zh-choicedp':'选择部门',
	'zh-choiceseat':'选择座位',
	'zh-choicepermissons':'选择权限',
	'zh-permisson':'权限',
	'zh-addsalary':'加薪5%',
	'zh-fire':'解雇',
	'zh-update':'更新',
	'zh-delete':'删除',
	'zh-msgDeleteDP':'确定删除这个部门吗？',
	'zh-openmeeting':'开会',
	'zh-stopmeeting':'散会',
	'zh-morechoice':'多选',
	'zh-meetingmax':'会议室只有13个座位',
	
	'zh-choicedpleader':'选择部门主管',
	
	'zh-curproj':'当前项目',
	'zh-projprocess':'项目进度',
	
	'zh-findetail':'财务详情',
	'zh-fintotalin':'总收入',
	'zh-fintotalout':'总支出',
	'zh-lastpager':'上一页',
	'zh-nextpager':'下一页',
	'zh-inmore':'盈利',
	'zh-outmore':'亏损',
	
	'zh-type':'类型',
	'zh-mark':'备注',
	'zh-adminman':'负责人',
	'zh-status':'状态',
	'zh-noncomplete':'未完成',
	'zh-complete':'已完成',
	'zh-doing':'进行中',
	'zh-unknow':'未知',
	
	'zh-businesstitle':'业务概览',
	'zh-hirestaff':'招聘员工',
	'zh-requreHightest':'要求极高',
	'zh-requreHight':'要求较高',
	'zh-requreHighNot':'要求不高',
	'zh-requreLow':'要求较低',
	'zh-addBusinessMsg':'确定新增这条业务吗？',
	'zh-doSucess':'操作成功',
	'zh-doFail':'操作失败',
	'zh-firewarnmsg':'解雇需要支付赔偿金，您确定解雇该员工吗？',
	'zh-addSalaryMsg':'确定给员工加薪吗',
	'zh-dpEdit':'部门编辑',
	'zh-eommitMsg':'确定提交吗',
	'zh-updateStaffMsg':'确定修改员工信息吗',
	
	'zh-payout':'支出',
	'zh-payin':'收入',
	'zh-typePaySalary':'工资发放',
	'zh-typeProjReward':'项目收入',
	'zh-typeProjFire':'项目赔偿',
	'zh-typeCmpPay':'日常开销',
	'zh-wait':'请稍后',
	'zh-year':'年',
	'zh-month':'月',
	'zh-day':'日',
	'zh-hour':'时',
	'zh-minute':'分',
	'zh-segment':'段',
	'zh-man':'男',
	'zh-woman':'女',
	'zh-choiceadp':'请选择一个部门',
	'zh-txtlen2-20':'长度在 2 到 20 个字符',
	'zh-txtlen5-20':'长度在 5 到 20 个字符',
	'zh-postnamerequire':'请输入岗位名称',
	'zh-seatrequire':'请选择一个座位',
	'zh-cancelbuisiness':'确定取消这个业务吗？',
	'zh-requirBusinessType':'请选择业务类型',
	'zh-requireResponse':'请选择执行人',
	'zh-requireFilter':'请选择筛选条件',
	'zh-requireSalary':'请填写薪资',
	'zh-requireAbility':'请至少选择一项能力',
	'zh-addTask':'添加业务',
	
	'zh-requestMan':'发起人',
	'zh-exeMan':'执行人',
	'zh-buisinessName':'业务名称',
	'zh-total':'总数',
	'zh-days':'工作日',
	'zh-handle':'操作',
	'zh-createBuisiness':'新建业务',
	'zh-choiceBuisiness':'选择业务',
	'zh-buisiness':'业务',
	'zh-choiceExeMan':'选择执行人',
	'zh-filter':'筛选',
	'zh-choiceFilter':'选择筛选条件',
	'zh-manage':'管理',
	'zh-develop':'开发',
	'zh-choiceAbility':'选择能力',
	'zh-advSalary':'建议薪资不要高于',
	'zh-cmpnamerequire':'请输入公司名称',
	'zh-ceonamerequire':'请输入您的名字',
	'zh-cmpname':'公司名称',
	'zh-cmpcreator':'创始人',
	
	'zh-readed':'已读',
	'zh-unreaded':'未读',
	
	'zh-addsalaryfire':'加薪20%挽留',
	'zh-agreefire':'同意离职',
	'zh-offworkreq':'离职申请',
	
	'zh-tmpoffworkstarttime':'开始日期',
	'zh-tmpoffworkendtime':'结束日期',
	'zh-back2seat':'回到座位上',
	'zh-menu':'菜单',
}

function getLocal(key){
	return local[language+"-"+key]
}
