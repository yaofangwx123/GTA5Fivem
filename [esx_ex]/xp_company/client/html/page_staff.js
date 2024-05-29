
var instance = new Vue({
	el: '#app',

	data: {
		activeName: 'staff',
		departments: [],
		company:null,
		secFunction:null,
		dialogStaffMenu: false,
		dialogDepartment: false,
		staffs: [],
		permissons: [],
		staffSelect: undefined,
		departmentSelect: undefined,
		showFullLoading: false,
		titleDepartmentDialog: null,
		selectionEnable:false,
		selectionStaffs:[],
		processBg:'#8e8e8e',
		notifications:[],
		departmentsTree:[],
		dialogDepartmentType: -1,//0 delete 1:new 2:edit
		unreadedNum:0,
		vv:false,
		defaultProps: {
		          children: 'children',
		          label: 'name'
		        },
		treeDpPro: {
		          children: 'children',
		          label: 'name'
		        },
		formRulesDepartment:{
			name: [{
					required: true,
					message: getLocal('choiceadp'),
					trigger: 'blur'
				},
				{
					min: 2,
					max: 20,
					message: getLocal('txtlen2-20'),
					trigger: 'blur'
				}
			],
			leaderId: [{
					required: true,
					message: getLocal('msgdpleader'),
					trigger: 'change'
				}
			],
			upDepartmentId: [{
					required: true,
					message: getLocal('msgupdp'),
					trigger: 'change'
				}
			]
		},
		 formRulesStaff:{
		 	departmentId: [{
		 			required: true,
		 			message: getLocal('choiceadp'),
		 			trigger: 'change'
		 		}
		 	],
			post: [{
		 			required: true,
		 			message: getLocal('postnamerequire'),
		 			trigger: 'blur'
		 		},
				
				{
					min: 2,
					max: 20,
					message: getLocal('txtlen2-20'),
					trigger: 'blur'
				}
		 	],
			seatId: [{
		 			required: true,
		 			message: getLocal('seatrequire'),
		 			trigger: 'change'
		 		}
		 	]
		 } 
	},
	methods: {
		toggleExtend: function(treeData){
		  treeData.extend = !treeData.extend;
		  this.$forceUpdate();
		},
		handleNodeClick(data) {
		        console.log(data);
		      },
		getMainType(type){
			if(type == 0){
				return getLocal('notifytype_offwork')
			}
			
			return ""
		},
		
		back2Seat(){
			let that = this
			sendMessageToClient(that,{
				action: "back2Seat",
				staff: that.staffSelect
			}, function(result) {
				let result_ = result
				notification(that,getLocal('tip'),result_.result?'success':'error',result_.result?getLocal('doSucess'):getLocal('doFail'))
				
				
			},true)
		},
		fireStaff(){
			  let that = this
			  messageConfirm(that,getLocal('firewarnmsg'),function(result){
			  	if(result){
			  		
			  		sendMessageToClient(that,{
			  			action: "fireStaff",
			  			staff: that.staffSelect
			  		}, function(result) {
			  			that.dialogStaffMenu = false
			  			let result_ = result
			  			notification(that,getLocal('tip'),result_.result?'success':'error',result_.result?getLocal('doSucess'):getLocal('doFail'))
						if(result_.result){
							that.getCompany()
						}		
			  			
			  		},true)
			  	}
			  })
			  
		  },
		  deleteDepartment(){
			  let that = this
			  messageConfirm(that,getLocal('msgDeleteDP'),function(result){
			  		
			  	if(result)
				{
					sendMessageToClient(that,{
						action: "deleteDepartment",
						id: that.departmentSelect.id
					}, function(result_) {
						let result = result_
					
						notification(that,getLocal('tip'), result.result ? 'success' : 'error', result.result ?getLocal('doSucess'):result.msg)
							
						if(result.result){
							that.dialogDepartment = false
							that.dialogDepartmentType = -1
							that.vv = false
							that.getCompany()
						}	
							
						
					
					}, true)
				}
			  })
		  },
		addStaffSalary(){
			let that = this
			
			messageConfirm(that,getLocal('addSalaryMsg'),function(result){
		
				sendMessageToClient(that,{
					action: "addStaffSalary",
					staff: that.staffSelect
				}, function(result_) {
					let result = result_
				
					notification(that,getLocal('tip'), result.result ? 'success' : 'error', result.result ?getLocal('doSucess'):getLocal('doFail'))
						
					if(result.result){
						that.staffSelect = result.staff
						for(let staff of that.company.staffs){
							if(staff.id == that.staffSelect.id){
								staff.honest = that.staffSelect.honest
								staff.salary = that.staffSelect.salary
								break
							}
						}
					}	
						
					
				
				}, true)
			})
		},
		getheadUrl(head){
			return 'data:image/png;base64,' + headers[head]
		},
		addDepartment() {
			this.departmentSelect = {
				comId:this.company.id,
				name:null,
				upDepartmentId:undefined,
				upDepartmentName:null,
				leaderId:undefined,
				leaderName:null
			}
			this.dialogDepartment = true
			this.titleDepartmentDialog = getLocal('adddp')
		},
		moreChoice(){
			this.selectionEnable = !this.selectionEnable 
			this.selectionStaffs = []
		},
		openMeeting(){
			
			if(this.selectionStaffs.length > 13){
				notification(that,getLocal('tip'), 'error', getLocal('meetingmax'))	
				return
			}
			
			let that = this
			sendMessageToClient(this,{action:"openMeeting",staffs:this.selectionStaffs},function(result){
				if(result.result){
					that.moreChoice()
					that.company.meetingTime = result.meetingTime
				}
				
				notification(that,getLocal('tip'), result.result ? 'success' : 'error', result.result ? getLocal('doSucess'):getLocal('doFail'))
			},true)
			
			
		},
		stopMeeting(){

			
			let that = this
			sendMessageToClient(this,{action:"stopMeeting"},function(result){
				if(result.result){
					that.moreChoice()
					that.company.meetingTime = 0
				}
				
				notification(that,getLocal('tip'), result.result ? 'success' : 'error', result.result ? getLocal('doSucess'):getLocal('doFail'))
			},true)
			
			
		},
		handleSelectionStaffsChange(values){
			this.selectionStaffs = values
			//console.log('selectionStaffs '+JSON.stringify(this.selectionStaffs))
		},
		rowClickStaff(row) {
			//console.log('rowClickStaff '+JSON.stringify(row)+"\n"+JSON.stringify(company.staffs))
			
			if(row.playerId == this.company.owner || this.selectionEnable){
				return
			}
			
			if( row.leaderId)
			{
				this.departmentSelect = JSON.parse(JSON.stringify(row))
				this.titleDepartmentDialog = this.departmentSelect.name
				this.dialogDepartmentType = 0
				this.vv = true
				return
			}
			
			this.staffSelect = JSON.parse(JSON.stringify(row))
			
			for(let permisson of this.company.permissons){
				
				if(permisson.id == PERMISSION_SALARY || permisson.id == PERMISSION_Hire|| permisson.id == PERMISSION_Fire|| permisson.id == PERMISSION_Rule){
					permisson.disabled = !isStaffHaveSkill(this.staffSelect,Skill_Resource)
					
				}else if(permisson.id == PERMISSION_PROJECT){
					permisson.disabled = !isStaffHaveSkill(this.staffSelect,Skill_Project)
					
				}else{
					permisson.disabled = true
				}
				
				console.log(permisson.id+" "+permisson.disabled)
				
			}
			
			this.dialogStaffMenu = true

		},

		departmentMenuChoice(typeMenu){
			
			this.dialogDepartmentType = typeMenu
			if(this.dialogDepartmentType == 1)
			{
				this.deleteDepartment()
			}
			else if(this.dialogDepartmentType == 2)
			{
				this.titleDepartmentDialog = getLocal('adddp')
				this.departmentSelect.name = ''
				this.departmentSelect.upDepartmentId = this.departmentSelect.id
				this.departmentSelect.leaderId = null
				this.departmentSelect.id = 0
				
				for(let dp of this.company.departments)
				{
					if(dp.id == this.departmentSelect.id )
					{
						dp.dpselected = true
					}
					else
					{
						dp.dpselected = isDepartmentUnder(this.company.departments,this.departmentSelect,dp)
					}
					
				}
				
			}
			else
			{
				this.titleDepartmentDialog = this.departmentSelect.name
				for(let dp of this.company.departments)
				{
					if(dp.id == this.departmentSelect.id )
					{
						dp.dpselected = true
					}
					else
					{
						dp.dpselected = isDepartmentUnder(this.company.departments,this.departmentSelect,dp)
					}
					
				}
			}
		},
		rightClick(row, column, event) {
			
			/* if(!row.upDepartmentId)
			{
				return
			} */

			console.log("dddddddddddd")
			if(row.leaderId)
			{
			
			}
			
		},
		rowClickNotication(row){
			
		},
		
		/* getDepartments(){
			let that = this
			getDepartments(this,this.comId,function(res){
					that.departments = res
						for (let department of that.departments) {
							department.createTime = getTimeFromMills(department.createTime)
				
							//所属部门
							for (let department2 of that.departments) {
								if (department2.id == department.upDepartmentId) {
									department.upDepartmentName = department2.name
									break
								}
							}
						}
			})
		},
		getStaffs(){
			let that = this
			getStaffs(this,this.comId,function(res){
				that.staffs = res
						for (let staff of that.staffs) {
							staff.createTime = getTimeFromMills(staff.createTime)
							staff.permissons = !staff.permissons ? [] : JSON.parse(staff.permissons)
							staff.sex = staff.sex == 1 ? '男' : '女'
						}
			})
		},
		getPermissions(){ 
			let that = this
			getPermissions(this,function(res){
				that.permissons = res
			})
		}, */
		
		departmentConfirm(formName) {
			let that = this
			
			  this.$refs[formName].validate((valid) => {
			          if (valid) {
			            messageConfirm(that,getLocal('eommitMsg'),function(result){
							
							if(result)
							{
								that.dialogDepartment = false
								let upDp = getDepartmentById(that.departmentSelect.upDepartmentId,that.company.departments)
								that.departmentSelect.upDepartmentName = upDp?upDp.name:null
								console.log(JSON.stringify(that.departmentSelect))
								let isAdd = that.titleDepartmentDialog === getLocal('adddp')	
								sendMessageToClient(that,{
									action: isAdd ? "addDepartment" : "updateDepartment",
									department: that.departmentSelect
								}, function(result_) {
									let result = result_
									if (result.result) {
										that.getCompany()
								
									}
									
								notification(that,getLocal('tip'), result.result ? 'success' : 'error', result.result ? getLocal('doSucess'):getLocal('doFail'))
							
								that.dialogDepartmentType = -1
								that.vv = false
			            	
			            	}, true)
							}
							
			            })
			          } else {
			            console.log('error submit!!');
			            return false;
			          }
			        });
			
			
			
			
			

		},
		getDpStaffsStatusList()
		{
			let result = []
			for(let staff of this.company.staffs)
			{
				staff.dpSelect = true
				/* for(let dp of this.company.departments)
				{
					if(staff.id == dp.leaderId && staff.id != this.departmentSelect.leaderId)
					{
						staff.dpSelect = false
						break
					}
				} */
				
				
				
				
				result.push(staff)
			}
			
			return result
		},
		getSalary(){
			let total = 0
			for(let staff of this.company.staffs){
				total += staff.salary
			}
			return total
		},
		updateStaff(formName) {
			let that = this
			
			this.$refs[formName].validate((valid) => {
			        if (valid) {
			         
			         messageConfirm(that,getLocal('updateStaffMsg'),function(result){
			         	if(result){
			         		that.dialogStaffMenu = false
			         		that.staffSelect.departmentName = getDepartmentById(that.staffSelect.departmentId,that.company.departments).name
			         		console.log(JSON.stringify(that.staffSelect))
			         		
			         		sendMessageToClient(that,{
			         			action: "updateStaffFromWeb",
			         			staff: that.staffSelect
			         		}, function(result_) {
			         			let result = result_
			         			if (result.result) {
			         				that.getCompany()
			         			}
			         			notification(that,getLocal('tip'), result.result ? 'success' : 'error', result.result ? getLocal('doSucess'):getLocal('doFail'))
			         		
			         		}, true)
			         	}
			         })
					 
					 
			        } else {
			          console.log('error submit!!');
			          return false;
			        }
			      });
			
		
			
			
			
		},

		
		handleClick(tab, event) {
			 console.log(tab, event);
			if (tab.name == 'notification') {
				let that = this
				sendMessageToClient(that,{
					action: "getNotifications",
					comId: that.company.id,
					page:0
				}, function(result_) {
					that.notifications = result_
					for(let notification of that.notifications){
						notification.createTime = getCCmTime(notification.createTime)
					}
				})
			}
		}
		,
		close() {
			
			goMainPage()
		},
		getCompany(){
			let that = this
			//that.company = JSON.parse("")
			getMyCompany(this,function(result){
				that.company = result
				
				for(let chair of that.company.chairs){
					chair.enable = true
					let staff = getStaffBySeatId(that.company.staffs,chair.id)
					
					if(staff != null){
						chair.txt = chair.txt + ' '+ staff.name + ' ['+staff.departmentName+'-'+staff.post+']'
						
					}
				}
				
				if(that.company.meetingTime > 0){
					if(that.secFunction){
						clearInterval(that.secFunction)
						that.secFunction = null
					}	
					that.secFunction = setInterval(function(){
						
						if(that.company.meetingTime > 0){
							--that.company.meetingTime
							
						}else{
							clearInterval(that.secFunction)
						}
						//console.log("jsmeeting"+that.company.meetingTime)
						
					},1000)
				}
				
				
				//对员工进行树形结构管理
				let dps = JSON.parse(JSON.stringify(that.company.departments))
				let dpTree =  JSON.parse(JSON.stringify(that.company.departments[0]))
				
				flatDepartmentToTree(dps,dpTree)
				that.departmentsTree = [dpTree]
				
				
				
			//	console.log(JSON.stringify(that.departmentsTree,undefined,2))
				
				let dpsTmp = JSON.parse(JSON.stringify(dpTree))
				
				//let treeStaffs = JSON.parse(JSON.stringify(that.company.departments))
				
		
				flatArrayToTree3(dpsTmp,that.company.staffs)
				console.log(JSON.stringify(dpsTmp,undefined,2))
				//console.log("---------------------1111111111111111111-----------------------------------")
				
				//console.log(JSON.stringify(boss))
				
			/* 	boss.staffs.sort(function(a,b){
					  if (a.groupName < b.groupName) {
					     return -1;
					   }
					   if (a.groupName > b.groupName) {
					     return 1;
					   }
					   return 0;
				}) */
				
				//
			
				
				//getStaffsOfLeader(boss,that.company.departments,that.company.staffs)
				
				//console.log("---------------------22222222222222222-----------------------------------")
				
				//console.log(JSON.stringify(boss))
				//console.log(JSON.stringify(boss))
				
				that.company.tree = [dpsTmp]
				
				
				
			})
		}

	},

	mounted() {
		//this.getDepartments()
		//this.getStaffs()
		this.local = getLocal
		this.getCompany()
	},
	beforeDestroy() {
		if(this.secFunction){
			clearInterval(this.secFunction)
			this.secFunction = null
		}	
	}

})