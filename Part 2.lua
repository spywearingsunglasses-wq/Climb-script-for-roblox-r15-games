local P,W,U,AS,IS=game:GetService("Players"),game:GetService("Workspace"),game:GetService("UserInputService"),game:GetService("AssetService"),game:GetService("InsertService")
local L,S=P.LocalPlayer,getgenv().FEC

S.animIds={Climb="rbxassetid://507765644",SpiderRun="rbxassetid://1083182000",SpiderIdle="rbxassetid://1083445855",ClimbOver="rbxassetid://656117878",Ceil="rbxassetid://1083222527"}
function S.stopTracks()for _,tr in pairs(S.tracks)do if tr and tr.IsPlaying then tr:Stop(0.12)end end S.tracks={}end

function S.unpackUGC()
 pcall(function()for _,it in ipairs(AS:GetBundleDetailsAsync(245332605334281).Items or{})do if it.Type=="Asset"then local ok,mdl=pcall(function()return IS:LoadAsset(it.Id)end)if ok and mdl then for _,d in ipairs(mdl:GetDescendants())do if d:IsA("Animation")and d.AnimationId~=""then local pn=string.lower(d.Parent.Name)if string.find(pn,"run")or string.find(pn,"walk")then S.animIds.SpiderRun=d.AnimationId elseif string.find(pn,"idle")then S.animIds.SpiderIdle=d.AnimationId elseif string.find(pn,"climb")then S.animIds.Climb=d.AnimationId end end end end end end end)
 pcall(function()local ok,mdl=pcall(function()return IS:LoadAsset(117220698427723)end)if ok and mdl then for _,d in ipairs(mdl:GetDescendants())do if d:IsA("Animation")and d.AnimationId~=""then S.animIds.ClimbOver=d.AnimationId break end end end end)
end

function S.loadTracks(hum)
 S.stopTracks()local anim=hum:FindFirstChildOfClass("Animator")if not anim then return end
 task.spawn(function()S.unpackUGC()for k,aid in pairs(S.animIds)do local a=Instance.new("Animation")a.AnimationId=aid local ok,tr=pcall(function()return anim:LoadAnimation(a)end)if ok and tr then tr.Priority=Enum.AnimationPriority.Action tr.Looped=true S.tracks[k]=tr end end end)
end

function S.startVault()
 local c=L.Character local h,hr=c and c:FindFirstChildOfClass("Humanoid"),c and c:FindFirstChild("HumanoidRootPart")if not h or not hr or not S.grabbed or S.vaulting then return end
 local rp=RaycastParams.new()rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={c,S.rig,S.cursors.L,S.cursors.R}
 local mid,fwd=(S.handL+S.handR)*0.5,Vector3.new(-S.smoothNorm.X,0,-S.smoothNorm.Z)fwd=fwd.Magnitude>0.01 and fwd.Unit or hr.CFrame.LookVector
 local hit=W:Raycast(mid+Vector3.new(0,4.5,0)+fwd*2.4,Vector3.new(0,-6.5,0),rp)
 local goal=hit and(hit.Position+Vector3.new(0,h.HipHeight+hr.Size.Y*0.5+0.6,0))or(mid+Vector3.new(0,h.HipHeight+1.8,0)+fwd*2.2)
 S.vaulting,S.vaultT,S.vStart,S.vEnd=true,0,hr.CFrame,CFrame.lookAt(goal,goal+fwd,Vector3.yAxis)if S.pullBtn then S.pullBtn.Visible=false end
end

function S.buildUI()
 if S.gui then S.gui:Destroy()end local gui=Instance.new("ScreenGui",L:WaitForChild("PlayerGui"))gui.Name,gui.ResetOnSpawn="FEClimbHUD",false S.gui=gui
 local function btn(pos,sz,txt,vis)local b=Instance.new("TextButton",gui)b.Size,b.Position,b.Visible,b.BackgroundColor3,b.BackgroundTransparency,b.TextColor3,b.Font,b.TextSize,b.Text=sz,pos,vis,Color3.fromRGB(24,24,30),0.15,Color3.new(1,1,1),Enum.Font.GothamBold,11,txt Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)local st=Instance.new("UIStroke",b)st.Color,st.Thickness=Color3.fromRGB(160,160,175),1.4 return b end
 S.lbl=Instance.new("TextLabel",gui)S.lbl.Size,S.lbl.Position,S.lbl.BackgroundColor3,S.lbl.BackgroundTransparency,S.lbl.TextColor3,S.lbl.Font,S.lbl.TextSize,S.lbl.Text=UDim2.new(0,255,0,26),UDim2.new(0.5,-127,0,10),Color3.fromRGB(20,20,25),0.2,Color3.fromRGB(225,225,235),Enum.Font.GothamBold,11,"🕹️ FE CLIMB: STANDBY"Instance.new("UICorner",S.lbl).CornerRadius=UDim.new(1,0)
 S.modeBtn=btn(UDim2.new(0.5,-152,0,42),UDim2.new(0,162,0,28),"🕹️ MODE: STICKS",true)S.modeBtn.MouseButton1Click:Connect(function()S.mode=(S.mode=="Sticks"and"Direct")or(S.mode=="Direct"and"Auto")or(S.mode=="Auto"and"Spider")or"Sticks"S.modeBtn.Text="MODE: "..string.upper(S.mode)end)
 S.vaultBtn=btn(UDim2.new(0.5,16,0,42),UDim2.new(0,136,0,28),"⚡ VAULT: ON",true)S.vaultBtn.MouseButton1Click:Connect(function()S.autoVault=not S.autoVault S.vaultBtn.Text=S.autoVault and"⚡ VAULT: ON"or"⚡ VAULT: OFF"end)
 local function mkPad(tag,isL)
  local f=Instance.new("Frame",gui)f.Size,f.BackgroundColor3,f.BackgroundTransparency,f.Active,f.Visible=UDim2.new(0,60,0,60),Color3.fromRGB(26,26,32),0.2,true,false Instance.new("UICorner",f).CornerRadius=UDim.new(1,0)
  local t=Instance.new("TextLabel",f)t.Size,t.BackgroundTransparency,t.Text,t.TextColor3,t.Font,t.TextSize=UDim2.new(1,0,1,0),1,tag,Color3.new(1,1,1),Enum.Font.GothamBold,15
  local tc,last=nil,Vector2.zero
  f.InputBegan:Connect(function(i)if not tc and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1)then tc,last=i,Vector2.new(i.Position.X,i.Position.Y)if isL then S.dragL=true else S.dragR=true end end end)
  U.InputChanged:Connect(function(i)if i==tc then local cur=Vector2.new(i.Position.X,i.Position.Y)local d=cur-last last=cur if isL then S.dL=S.dL+d else S.dR=S.dR+d end end end)
  U.InputEnded:Connect(function(i)if i==tc then tc=nil if isL then S.dragL,S.dL=false,Vector2.zero else S.dragR,S.dR=false,Vector2.zero end end end)return f
 end
 S.padL,S.padR=mkPad("L",true),mkPad("R",false)
 local function mkStk(pos,tag,col,isL)
  local b=Instance.new("Frame",gui)b.Size,b.Position,b.BackgroundColor3,b.BackgroundTransparency,b.Active,b.Visible=UDim2.new(0,108,0,108),pos,Color3.fromRGB(20,20,26),0.25,true,false Instance.new("UICorner",b).CornerRadius=UDim.new(1,0)local bs=Instance.new("UIStroke",b)bs.Color,bs.Thickness=col,2
  local k=Instance.new("Frame",b)k.Size,k.Position,k.BackgroundColor3,k.BackgroundTransparency=UDim2.new(0,44,0,44),UDim2.new(0.5,-22,0.5,-22),col,0.2 Instance.new("UICorner",k).CornerRadius=UDim.new(1,0)
  local kt=Instance.new("TextLabel",k)kt.Size,kt.BackgroundTransparency,kt.Text,kt.TextColor3,kt.Font,kt.TextSize=UDim2.new(1,0,1,0),1,tag,Color3.new(1,1,1),Enum.Font.GothamBold,14
  local tc=nil local function upd(i)local ctr=b.AbsolutePosition+b.AbsoluteSize*0.5 local v=Vector2.new(i.Position.X,i.Position.Y)-ctr if v.Magnitude>38 then v=v.Unit*38 end k.Position=UDim2.new(0.5,v.X-22,0.5,v.Y-22)local nm=Vector2.new(v.X/38,-v.Y/38)if isL then S.joyL=nm else S.joyR=nm end end
  b.InputBegan:Connect(function(i)if not tc and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1)then tc=i upd(i)end end)
  U.InputChanged:Connect(function(i)if i==tc then upd(i)end end)
  U.InputEnded:Connect(function(i)if i==tc then tc=nil k.Position=UDim2.new(0.5,-22,0.5,-22)if isL then S.joyL=Vector2.zero else S.joyR=Vector2.zero end end end)return b
 end
 S.stickL,S.stickR=mkStk(UDim2.new(0,26,1,-140),"L",Color3.fromRGB(90,210,255),true),mkStk(UDim2.new(1,-134,1,-140),"R",Color3.fromRGB(255,115,115),false)
 S.pullBtn=btn(UDim2.new(1,-125,1,-255),UDim2.new(0,105,0,38),"⬆️ PULL UP",false)S.pullBtn.MouseButton1Click:Connect(S.startVault)
 S.jmpBtn=btn(UDim2.new(1,-125,1,-210),UDim2.new(0,105,0,38),"⬆️ JUMP",true)
 S.jmpBtn.MouseButton1Click:Connect(function()local c=L.Character local h,hr=c and c:FindFirstChildOfClass("Humanoid"),c and c:FindFirstChild("HumanoidRootPart")if not h or not hr then return end if S.grabbed and not S.vaulting then local kd=S.smoothNorm.Y<-0.6 and Vector3.new(0,-18,0)or S.smoothNorm*34+Vector3.new(0,48,0)S.resetState(c)h:SetStateEnabled(12,false)hr.AssemblyLinearVelocity=kd elseif not S.grabbed then h.Jump=true end end)
end
print("Part 2 Loaded!")
