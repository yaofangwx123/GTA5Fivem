	var instance = new Vue({
		  el: '#app',
		  data: {
			company:null,
			tasks:[],
			actName:getLocal('businesstitle'),
			taskTag:null,
			dialogAddTask:false,
			ceoPermisson:[{
				id : PERMISSION_Hire,
				title : getLocal('hirestaff')
			}],
			skillsManage:[],
			skillsDevel:[],
			skillsManageModel:'',
			skillsDevelModel:[],
			isLeaderSkill:false,
			exeNonSelect:false,
			adviceSalary:'',
			matchLevels:[{
				level:100,
				txt:getLocal('requreHightest')
			},
			{
				level:80,
				txt:getLocal('requreHight')
			},
			{
				level:50,
				txt:getLocal('requreHighNot')
			},
			{
				level:10,
				txt:getLocal('requreLow')
			}
			],
			postType:getLocal('manage'),
			noDialogEdit:false,
			formRules:{
				permissonId: [{
						required: true,
						message: getLocal('requirBusinessType'),
						trigger: 'change'
					}
				],
				responseId: [{
						required: true,
						message: getLocal('requireResponse'),
						trigger: 'change'
					}
				],
				data:{
						departmentId: [{
								required: true,
								message: getLocal('choiceadp'),
								trigger: 'change'
							}
						],
						matchLevel: [{
								required: true,
								message: getLocal('requireFilter'),
								trigger: 'change'
							}
						],
						salary: [{
								required: true,
								message: getLocal('requireSalary'),
								trigger: 'blur'
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
						],
				}
				
				
			}
		  },
		  
		  computed:
		  {
		
		  },
		  methods:{
			cancelTask(task){
				let that = this
				
				messageConfirm(that,getLocal('cancelbuisiness'),function(result){
					if(result){
						
						sendMessageToClient(that,{
							action: "cancelTask",
							task: task
						}, function(result) {
							let result_ = result
							notification(that,getLocal('tip'),result_.result?'success':'error',result_.result?getLocal('doSucess'):getLocal('doFail'))		
							if(result_.result)
							{
								if(task.permissonId == PERMISSION_Hire){
									let data = JSON.parse(task.data)
									for(let chair of that.company.chairs){
											
										if(data.seatId == chair.id){
											chair.enable = true
											break
										}
									}
									
								}
								
								
								
								that.getTasks()
							}
						},true)
					}
				})
			},
			businessTypeChange(permisson){
				//筛选有这个技能的员工
				//this.taskTag.responseId = ""
				this.exeNonSelect = false
				
				
				//console.log("permisson "+permisson)
				for(let staff of this.company.staffs){
					if(permisson == PERMISSION_Fire){
						staff.disabled = staff.id != this.company.myStaffId
					}else{
						staff.disabled = isStaffHavePermisson(staff,permisson)
					}
					
					
				}	
				
			},
			skillSelect(){
				let maxSalary = 0
				if(this.postType == getLocal('manage')){
					this.skillsDevelModel = []
					maxSalary += this.company.skills[this.skillsManageModel].rate
				}else{
					this.skillsManageModel = ''
					
					for(let skillSelect of this.skillsDevelModel){
						maxSalary += this.company.skills[skillSelect].rate
					}
				}
				
				this.adviceSalary = maxSalary == 0?'':getLocal('advSalary')+maxSalary
				
			},
			businessExeStaff(exeStaffId){
				
				//老板只能招聘人事经理，由人事经理去做事情
				//console.log("businessExeStaff "+exeStaffId)
				 if(exeStaffId == this.company.myStaffId && this.taskTag.permissonId == PERMISSION_Hire){
					this.exeNonSelect = true
					this.postType = getLocal('manage')
					this.skillsManageModel = Skill_Resource
					
					this.skillSelect()
					
				}else{
					this.exeNonSelect = false
					this.skillsDevelModel = []
				} 
				
			},
			
			requestStatus(status){
				if(status == 0){
					return getLocal('doing')
				}
				else if(status == 1){
					return getLocal('complete')
				}
				else if(status == 2){
					return getLocal('noncomplete')
				}else{
					return getLocal('unknow')
				}
			},  
			close(){
				goMainPage()
			},
			addTask(){
				
				for(let chair of this.company.chairs){
						
					for(let task of this.tasks){
						if(task.permissonId == PERMISSION_Hire){
							let data = JSON.parse(task.data)
							if(data.seatId == chair.id){
								chair.enable = false
								break
							}
							
						}
					}
				}
				
				if(this.taskTag == null){
					this.taskTag = {
						comId:this.company.id,
						requestId:undefined,
						repsponseId:undefined,
						permissonId:undefined,
						status:0,
						cntTotal:1,
						workdays:0,
						reportUp_:false,
						reportUp:0,
						data:{},
						desc:''
					}
				}else{
					this.taskTag.data.seatId = undefined
					this.taskTag.status = 0
					this.taskTag.reportUp_ = false
					this.taskTag.reportUp = 0
				}
				this.noDialogEdit = false
				this.dialogAddTask = true
			},
			rowClickTask(task){
				if(task.permissonId == PERMISSION_Hire ){
					this.taskTag = JSON.parse(JSON.stringify(task))
					this.taskTag.data = JSON.parse(task.data)
					for(let skill of this.taskTag.data.skills){
						if(skill == Skill_Resource || skill == Skill_Project){
							this.postType = getLocal('manage')
							this.skillsManageModel = this.taskTag.data.skills[0]
						}else{
							this.postType = getLocal('develop')
							this.skillsDevelModel = this.taskTag.data.skills
						}
						this.noDialogEdit = true
						break
					}
					
					this.dialogAddTask = true
				}
				
				
			},
			addTaskConfirm(formName){
				
				let that = this
				
				this.$refs[formName].validate((valid) => {
				        if (valid) {
							
						if(that.skillsManageModel.length == 0 && that.skillsDevelModel.length == 0){
							
							notification(that,getLocal('tip'),'error',getLocal('requireAbility'))
							
							return
						}	
							
							
				          if(that.skillsManageModel.length == 0){
				          	that.taskTag.data.skills = that.skillsDevelModel
				          }else{
							  that.taskTag.data.skills = [that.skillsManageModel]
						  }
				          messageConfirm(that,getLocal('addBusinessMsg'),function(result){
				          	if(result){
				          		that.taskTag.reportUp = that.taskTag.reportUp_?1:0
				          		sendMessageToClient(that,{
				          			action: "addRequest",
				          			task: that.taskTag
				          		}, function(result) {
				          			that.dialogAddTask = false
				          			let result_ = result
				          			notification(that,getLocal('tip'),result_.result?'success':'error',result_.result?getLocal('doSucess'):getLocal('doFail'))		
				          			if(result_.result)
				          			{
				          				that.getTasks()
				          			}
				          		},true)
				          	}
				          })
				          
				        } else {
				          console.log('error submit!!');
				          return false;
				        }
				      });
							
				
				
			
				
				
			},


		/* 	getDepartments() {
				let that = this
				
				getDepartments(this,this.comId,function(result){
					that.departments = result
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
					that.getTasks()
				})
				

			},
			getStaffs() {
				let that = this
				
				getStaffs(this,this.comId,function(result){
					that.staffs = result
					for (let staff of that.staffs) {
						staff.createTime = getTimeFromMills(staff.createTime)
						staff.permissons = !staff.permissons ? [] : JSON.parse(staff.permissons)
						staff.sex = staff.sex == 1 ? '男' : '女'
					}
					that.getPermissions()
				})
			}, */
			getTasks() {
				let that = this
				sendMessageToClient(this,{
					action: "getRequests",
					comId: this.company.id
				}, function(result) {
			
				
					that.tasks = result
					for (let task of that.tasks) {
						task.createTime_ = getCCmTime(task.createTime)
						task.status = that.requestStatus(task.status)
						console.log("task.status "+task.status)
						for(let staff of that.company.staffs)
						{
							if(staff.id === task.requestId)
							{
								task.requestName = staff.name
							}
							if(staff.id === task.responseId)
							{
								task.responseName = staff.name
							}
						}
						
						for(let permisson of that.company.permissons)
						{
							if(permisson.id == task.permissonId)
							{
								task.permissonName = permisson.title
								break
							}
						}
						
						
					}
					//console.log("getCompanyStaffs "+JSON.stringify(that.staffs))
				})
			},
		/* 	getPermissions() {
				let that = this
				getPermissions(this,function(result){
					that.permissons = result
					console.log("getPermissions " + JSON.stringify(that.permissons))
					that.getDepartments()
				})
				
			}, */
			
		  },
		  mounted() {
			  let that = this
			  this.local = getLocal
			  getMyCompany(this,function(company){
				  that.company = company
				  let map = new Map(Object.entries(that.company.skills))
				  for(let skill of map.values()){
					  if(skill.id == Skill_Resource || skill.id == Skill_Project){
						   that.skillsManage.push(skill)
					  }else{
						   that.skillsDevel.push(skill)
					  }
					 
				  }
				  
				  that.getTasks()
			  })
		
			}
		})