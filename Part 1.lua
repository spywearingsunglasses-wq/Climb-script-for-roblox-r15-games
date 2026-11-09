local P,R,W,U=game:GetService("Players"),game:GetService("RunService"),game:GetService("Workspace"),game:GetService("UserInputService")
local L=P.LocalPlayer
for _,v in pairs(L:WaitForChild("Backpack"):GetChildren())do if v.Name=="🧗 Climb"then v:Destroy()end end
if L.PlayerGui:FindFirstChild("FEClimbHUD")then L.PlayerGui.FEClimbHUD:Destroy()end
if W:FindFirstChild("FEC_AnimRig")then W.FEC_AnimRig:Destroy()end

getgenv().FEC={active=false,grabbed=false,mode="Sticks",autoVault=true,atLedge=false,vaulting=false,vaultT=0,vStart=CFrame.new(),vEnd=CFrame.new(),turnT=0,phase=0,wNorm=Vector3.new(0,0,1),handL=Vector3.zero,handR=Vector3.zero,posL=Vector3.zero,posR=Vector3.zero,dragL=false,dragR=false,dL=Vector2.zero,dR=Vector2.zero,joyL=Vector2.zero,joyR=Vector2.zero,ap=nil,ao=nil,att=nil,rig=nil,rigJ={},tracks={},cursors={},lbl=nil,modeBtn=nil,vaultBtn=nil,padL=nil,padR=nil,stickL=nil,stickR=nil,pullBtn=nil,jmpBtn=nil,gui=nil}
local S=getgenv().FEC

function S.setControls(on)
 pcall(function()local c=require(L.PlayerScripts:WaitForChild("PlayerModule")):GetControls()if on then c:Enable()else c:Disable()end end)
 pcall(function()local g=L.PlayerGui:FindFirstChild("TouchGui")if g then g.Enabled=on end end)
end

function S.clearPhys()if S.ap then S.ap:Destroy()S.ap=nil end if S.ao then S.ao:Destroy()S.ao=nil end if S.att then S.att:Destroy()S.att=nil end end
function S.clearRig()if S.rig then S.rig:Destroy()S.rig=nil end S.rigJ={}end
function S.clearCursors()for _,p in pairs(S.cursors)do if p then p:Destroy()end end S.cursors={}end

function S.makeCursors()
 S.clearCursors()
 local function r(nm,col)local p=Instance.new("Part",W)p.Name,p.Shape,p.Size,p.Material,p.Color,p.Transparency,p.Anchored,p.CanCollide,p.CanQuery,p.CanTouch=nm,Enum.PartType.Cylinder,Vector3.new(0.08,1.35,1.35),Enum.Material.Neon,col,0.35,true,false,false,false return p end
 S.cursors={L=r("FEC_CL",Color3.fromRGB(90,210,255)),R=r("FEC_CR",Color3.fromRGB(255,115,115))}
end

function S.makeRig(c)
 S.clearRig()c.Archivable=true local cl=c:Clone()c.Archivable=false if not cl then return end cl.Name="FEC_AnimRig"
 for _,d in ipairs(cl:GetDescendants())do
  if d:IsA("BasePart")then d.Transparency,d.CanCollide,d.Massless,d.CanQuery,d.CanTouch=1,false,true,false,false
  elseif d:IsA("Decal")or d:IsA("Texture")then d.Transparency=1
  elseif d:IsA("Script")or d:IsA("LocalScript")or d:IsA("Sound")or d:IsA("Animator")then d:Destroy()end
 end
 local rHr,rH=cl:FindFirstChild("HumanoidRootPart"),cl:FindFirstChildOfClass("Humanoid")
 if rHr then rHr.Anchored=true end if rH then rH.PlatformStand,rH.DisplayDistanceType=true,Enum.HumanoidDisplayDistanceType.None end
 cl.Parent=W S.rig=cl
 for _,n in ipairs({"Root","Waist","Neck","LeftShoulder","RightShoulder","LeftElbow","RightElbow","LeftWrist","RightWrist","LeftHip","RightHip","LeftKnee","RightKnee","LeftAnkle","RightAnkle"})do S.rigJ[n]=cl:FindFirstChild(n,true)end
end

function S.makePhys(hr)
 S.clearPhys()local att=Instance.new("Attachment",hr)
 local ap=Instance.new("AlignPosition",hr)ap.Mode,ap.Attachment0,ap.MaxForce,ap.MaxVelocity,ap.Responsiveness,ap.Position=Enum.PositionAlignmentMode.OneAttachment,att,1e6,240,80,hr.Position
 local ao=Instance.new("AlignOrientation",hr)ao.Mode,ao.Attachment0,ao.MaxTorque,ao.Responsiveness,ao.CFrame=Enum.OrientationAlignmentMode.OneAttachment,att,1e6,80,hr.CFrame
 S.att,S.ap,S.ao=att,ap,ao
end

function S.resetState(c)
 S.grabbed,S.atLedge,S.vaulting,S.vaultT,S.turnT,S.dragL,S.dragR,S.dL,S.dR,S.joyL,S.joyR=false,false,false,0,0,false,false,Vector2.zero,Vector2.zero,Vector2.zero,Vector2.zero
 for _,v in pairs({S.padL,S.padR,S.stickL,S.stickR})do if v then v.Visible=false end end
 S.clearCursors()S.clearPhys()S.clearRig()S.setControls(true)if S.stopTracks then S.stopTracks()end if not c then return end
 local h,hr,an=c:FindFirstChildOfClass("Humanoid"),c:FindFirstChild("HumanoidRootPart"),c:FindFirstChild("Animate")
 if hr then hr.Anchored=false hr.AssemblyLinearVelocity,hr.AssemblyAngularVelocity=Vector3.zero,Vector3.zero end
 if an then an.Disabled=false end if h then h:SetStateEnabled(12,true)h.PlatformStand,h.AutoRotate=false,true end
 for _,d in pairs(c:GetDescendants())do if d:IsA("Motor6D")then d.Transform=CFrame.new()end end
end

function S.startVault()
 local c=L.Character local h,hr=c and c:FindFirstChildOfClass("Humanoid"),c and c:FindFirstChild("HumanoidRootPart")
 if not h or not hr or not S.grabbed or S.vaulting then return end
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={c,S.rig,S.cursors.L,S.cursors.R}
 local mid,fwd=(S.handL+S.handR)*0.5,Vector3.new(-S.wNorm.X,0,-S.wNorm.Z)fwd=fwd.Magnitude>0.01 and fwd.Unit or hr.CFrame.LookVector
 local hit=W:Raycast(mid+Vector3.new(0,4.5,0)+fwd*2.4,Vector3.new(0,-6.5,0),rp)
 local goal=hit and(hit.Position+Vector3.new(0,h.HipHeight+hr.Size.Y*0.5+0.6,0))or(mid+Vector3.new(0,h.HipHeight+1.8,0)+fwd*2.2)
 S.vaulting,S.vaultT,S.vStart,S.vEnd=true,0,hr.CFrame,CFrame.lookAt(goal,goal+fwd,Vector3.yAxis)
 if S.pullBtn then S.pullBtn.Visible=false end
end

function S.buildUI()
 if S.gui then S.gui:Destroy()end
 local gui=Instance.new("ScreenGui",L:WaitForChild("PlayerGui"))gui.Name,gui.ResetOnSpawn="FEClimbHUD",false S.gui=gui
 local function btn(pos,sz,txt,vis)
  local b=Instance.new("TextButton",gui)b.Size,b.Position,b.Visible,b.BackgroundColor3,b.BackgroundTransparency,b.TextColor3,b.Font,b.TextSize,b.Text=sz,pos,vis,Color3.fromRGB(24,24,30),0.15,Color3.new(1,1,1),Enum.Font.GothamBold,11,txt
  Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)local st=Instance.new("UIStroke",b)st.Color,st.Thickness=Color3.fromRGB(160,160,175),1.4 return b
 end
 S.lbl=Instance.new("TextLabel",gui)S.lbl.Size,S.lbl.Position,S.lbl.BackgroundColor3,S.lbl.BackgroundTransparency,S.lbl.TextColor3,S.lbl.Font,S.lbl.TextSize,S.lbl.Text=UDim2.new(0,255,0,26),UDim2.new(0.5,-127,0,10),Color3.fromRGB(20,20,25),0.2,Color3.fromRGB(225,225,235),Enum.Font.GothamBold,11,"🕹️ FE CLIMB: STANDBY"
 Instance.new("UICorner",S.lbl).CornerRadius=UDim.new(1,0)
 S.modeBtn=btn(UDim2.new(0.5,-152,0,42),UDim2.new(0,162,0,28),"🕹️ MODE: STICKS",true)
 S.modeBtn.MouseButton1Click:Connect(function()S.mode=(S.mode=="Sticks"and"Direct")or(S.mode=="Direct"and"Auto")or(S.mode=="Auto"and"Spider")or"Sticks"S.modeBtn.Text="MODE: "..string.upper(S.mode)end)
 S.vaultBtn=btn(UDim2.new(0.5,16,0,42),UDim2.new(0,136,0,28),"⚡ VAULT: ON",true)
 S.vaultBtn.MouseButton1Click:Connect(function()S.autoVault=not S.autoVault S.vaultBtn.Text=S.autoVault and"⚡ VAULT: ON"or"⚡ VAULT: OFF"end)
 local function mkPad(tag,isL)
  local f=Instance.new("Frame",gui)f.Size,f.BackgroundColor3,f.BackgroundTransparency,f.Active,f.Visible=UDim2.new(0,60,0,60),Color3.fromRGB(26,26,32),0.2,true,false Instance.new("UICorner",f).CornerRadius=UDim.new(1,0)
  local t=Instance.new("TextLabel",f)t.Size,t.BackgroundTransparency,t.Text,t.TextColor3,t.Font,t.TextSize=UDim2.new(1,0,1,0),1,tag,Color3.new(1,1,1),Enum.Font.GothamBold,15
  local tc,last=nil,Vector2.zero
  f.InputBegan:Connect(function(i)if not tc and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1)then tc,last=i,Vector2.new(i.Position.X,i.Position.Y)if isL then S.dragL=true else S.dragR=true end end end)
  U.InputChanged:Connect(function(i)if i==tc then local cur=Vector2.new(i.Position.X,i.Position.Y)local d=cur-last last=cur if isL then S.dL=S.dL+d else S.dR=S.dR+d end end end)
  U.InputEnded:Connect(function(i)if i==tc then tc=nil if isL then S.dragL,S.dL=false,Vector2.zero else S.dragR,S.dR=false,Vector2.zero end end end)
  return f
 end
 S.padL,S.padR=mkPad("L",true),mkPad("R",false)
 local function mkStk(pos,tag,col,isL)
  local b=Instance.new("Frame",gui)b.Size,b.Position,b.BackgroundColor3,b.BackgroundTransparency,b.Active,b.Visible=UDim2.new(0,108,0,108),pos,Color3.fromRGB(20,20,26),0.25,true,false Instance.new("UICorner",b).CornerRadius=UDim.new(1,0)
  local bs=Instance.new("UIStroke",b)bs.Color,bs.Thickness=col,2
  local k=Instance.new("Frame",b)k.Size,k.Position,k.BackgroundColor3,k.BackgroundTransparency=UDim2.new(0,44,0,44),UDim2.new(0.5,-22,0.5,-22),col,0.2 Instance.new("UICorner",k).CornerRadius=UDim.new(1,0)
  local kt=Instance.new("TextLabel",k)kt.Size,kt.BackgroundTransparency,kt.Text,kt.TextColor3,kt.Font,kt.TextSize=UDim2.new(1,0,1,0),1,tag,Color3.new(1,1,1),Enum.Font.GothamBold,14
  local tc=nil local function upd(i)local ctr=b.AbsolutePosition+b.AbsoluteSize*0.5 local v=Vector2.new(i.Position.X,i.Position.Y)-ctr if v.Magnitude>38 then v=v.Unit*38 end k.Position=UDim2.new(0.5,v.X-22,0.5,v.Y-22)local nm=Vector2.new(v.X/38,-v.Y/38)if isL then S.joyL=nm else S.joyR=nm end end
  b.InputBegan:Connect(function(i)if not tc and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1)then tc=i upd(i)end end)
  U.InputChanged:Connect(function(i)if i==tc then upd(i)end end)
  U.InputEnded:Connect(function(i)if i==tc then tc=nil k.Position=UDim2.new(0.5,-22,0.5,-22)if isL then S.joyL=Vector2.zero else S.joyR=Vector2.zero end end end)
  return b
 end
 S.stickL,S.stickR=mkStk(UDim2.new(0,26,1,-140),"L",Color3.fromRGB(90,210,255),true),mkStk(UDim2.new(1,-134,1,-140),"R",Color3.fromRGB(255,115,115),false)
 S.pullBtn=btn(UDim2.new(1,-125,1,-255),UDim2.new(0,105,0,38),"⬆️ PULL UP",false)S.pullBtn.MouseButton1Click:Connect(S.startVault)
 S.jmpBtn=btn(UDim2.new(1,-125,1,-210),UDim2.new(0,105,0,38),"⬆️ JUMP",true)
 S.jmpBtn.MouseButton1Click:Connect(function()local c=L.Character local h,hr=c and c:FindFirstChildOfClass("Humanoid"),c and c:FindFirstChild("HumanoidRootPart")if not h or not hr then return end if S.grabbed and not S.vaulting then local kd=S.wNorm.Y<-0.6 and Vector3.new(0,-18,0)or S.wNorm*34+Vector3.new(0,48,0)S.resetState(c)h:SetStateEnabled(12,false)hr.AssemblyLinearVelocity=kd elseif not S.grabbed then h.Jump=true end end)
end
print("Climb Part 1 Loaded!")
