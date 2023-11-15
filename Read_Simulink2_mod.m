%% Automatic debugging of First HIL Scenario simulink file.  

clc,clear all,close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Generate new simulink model file with name "new_model.mdl" for generating all blocks 
Output_model='new_model.mdl';
Output_model_name='new_model';
close_system(Output_model)
delete(Output_model)

warning( 'off' , 'all' )

%%% Current Directory  %%%%
Main_bath=pwd;

%%%%%%%%%%%%%%%%%%%
%%%% This part of code should be changed as mentioned
%%% Main Output Signal 
Output_Type= 'simulink/Commonly Used Blocks/Out1';

%% Change it to 
% Output_Type= 'NI VeriStand Blocks/NIVeriStand Out1';
%%%%%%%%%%%%%%%%%%%

%%% All Simulink File, Mask, and block names
open_system("First_HIL_Scenario.mdl"); %% Simulink File Name

Model_name= 'First_HIL_Scenario/Veh_1/Algorithm/'; %% Mask Name

Required_Block = 'SensorsInput'; %% Required input name


%%% Test Case for signal  %%%%%%%%%%%%%%%
%% Test signal in the required block
    flag0=getSimulinkBlockHandle(strcat(Model_name,'Test_Bus_Selector'));  %% check existence of test Demux
    
    %% Initially delete any existed test block and connected line
    if flag0~=-1
    delete_line(Model_name,'SensorsInput/1',strcat('Test_Bus_Selector','/1'))   %%       
    delete_block(strcat(Model_name,'Test_Bus_Selector'));
    end

    %%% Add block and connection line for test
    add_block('simulink/Commonly Used Blocks/Bus Selector',strcat(Model_name,'Test_Bus_Selector'));

    add_line(Model_name,strcat(Required_Block,'/1'), strcat('Test_Bus_Selector','/1'));

    %%% Getting the whole input signals to be distributed in several bus
    %%% selectors (Demuxes)
    %% All Input Signals
    Input_Signals=get_param(strcat(Model_name,'Test_Bus_Selector'), 'InputSignals');

    %%% Deleting block and connection line after test
    delete_line(Model_name,'SensorsInput/1',strcat('Test_Bus_Selector','/1'))        
    delete_block(strcat(Model_name,'Test_Bus_Selector'));
    


h = new_system;
set_param(h,"Name",Output_model_name)
open_system(h)
Output_model=save_system(h,'new_model.mdl')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% Add Block with input to emulate SensorsInput
add_block('simulink/Commonly Used Blocks/In1',strcat(Output_model_name,'/SensorsInput'));

%%% For Loop for All Sensor Signals for separation on several Demuxes 
iv=1;
for i=1:size(Input_Signals,1)

    %%% Counting Sensors with names
    Element = Input_Signals(i,1);

    Element_n = Element{1};

    Element_name = cell2mat(Element_n(1)); %% Sensor Name

    Ch_ext = strfind(Element_name,'RadarSensor');     %%% Flag to Check Radar Signals
    if isempty(Ch_ext)
        Radar_Flag=0;
    else
        Radar_Flag=1;
    end
    %%% Name for the Bus Selector of every sensor
    Bus_Selector_name = strcat('Bus Selector:',Element_name);

    %%% Whole directory name for the Bus Selector
    Bus_Selector_fname= strcat(Output_model_name,'/Bus Selector: ',Element_name);
    
    %%%% Selection of Bus selector with Position for every bus selector of every sensor
    ix=i*10000;
    ic=strcat('[ ',num2str([230 -110+ix 240 110+ix]),']');
    add_block('simulink/Commonly Used Blocks/Bus Selector',Bus_Selector_fname, 'Position',ic);
    add_line(Output_model_name,'SensorsInput/1', strcat(Bus_Selector_name,'/1'));
    %%%%%%%%%%%%%%%%%
    
    %%% Name of objects for every sensor
    Ele_objects  = Element_n(2); 

    Ele_objects_e = Ele_objects{:}; 

    %%% Size of elements of every sensor
    Element_objects_no = size(Ele_objects_e,1); 

    Block_names='';  %%% Initial Selected Elements for Every Demux
    %% For loop for objects inside every sensor 
    in=0;
    Bus_Selector_name2='';
    for j =1:Element_objects_no

        Sens_obj= cell2mat(Ele_objects_e(j)); %% Sensor data elements

        Whole_name=strcat(Element_name,'.',Sens_obj); %% Name of every element

        %%% Generating position for every output
        Fac=round(250/(Element_objects_no+1));
        ic=strcat('[ ',num2str([430+Fac*j -110+ix+40*Fac*j 460+Fac*j -100+ix+40*Fac*j]),']');
        
        %%% Genrate outputs with name of every output.
        Output_fname=strcat(Output_model_name,'/',Whole_name);
        add_block(Output_Type,Output_fname, 'Position',ic);
        
        %%% Generate "Selected Elements" for every bus selector
        if j<Element_objects_no
        Block_names = strcat(Block_names,Whole_name,',');
        else
        Block_names = strcat(Block_names,Whole_name);       
        end
        
        
        if Radar_Flag==1
        %%%% Selection of Bus selector with Position for every bus selector of every sensor
        ik=1;
        if contains(Sens_obj,'OBJ')
        %%% Whole directory name for the Bus Selector
        Bus_Selector_name2= strcat('Bus Selector: ',Element_name,'_',Sens_obj,'_BS');
        
        Bus_Selector_fname2= strcat(Output_model_name,'/Bus Selector: ',Element_name,'_',Sens_obj,'_BS');
        ic=strcat('[ ',num2str([930 -110+ix+(2*in*600) 940 -110+ix+(2*in+1)*600]),']');
        add_block('simulink/Commonly Used Blocks/Bus Selector',Bus_Selector_fname2, 'Position',ic);
        Block_names2='';
        
        for ig=1:64
        Whole_name2=strcat(Whole_name,'_',num2str(ig));
        ic=strcat('[ ',num2str([1230 -110+ix+(2*in*600)+(2*ig-1)*8 1240 -110+ix+(2*in*600)+(2*ig)*8]),']');
        add_block(Output_Type,strcat('new_model/',Whole_name2), 'Position',ic);

        %%% Generate "Selected Elements" for every bus selector
        if ig<64
        Block_names2 = strcat(Block_names2,Whole_name2,',');
        else
        Block_names2 = strcat(Block_names2,Whole_name2);       
        end

        end
        set_param( strcat(Output_model_name,'/Bus Selector: ',strcat(Element_name,'_',Sens_obj,'_BS')), 'OutputSignals', Block_names2);
        %% For loop for connecting every Sebsor Bus selector with every relevant sensor object  
        for ig=1:64
        Whole_name2=strcat(Whole_name,'_',num2str(ig));
        add_line(Output_model_name, strcat(Bus_Selector_name2,'/',num2str(ig)), strcat(Whole_name2,'/1'));
        end
        in=in+1;
        end
        end
        %%%%%%%%%%%%%%%%%
        iv=iv+1;
        Bus_Selector_name2i(j)=cellstr(Bus_Selector_name2);
    end   %%% end of generating sensors objects for loop at line 101

%%% Write Selected elements for every bus selector
set_param( strcat(Output_model_name,'/Bus Selector: ',Element_name), 'OutputSignals', Block_names);
       
%% For loop for connecting every Sebsor Bus selector with every relevant sensor object  
    for j=1:Element_objects_no
        Sens_obj= cell2mat(Ele_objects_e(j));
        Whole_name=strcat(Element_name,'.',Sens_obj);
        add_line(Output_model_name, strcat(Bus_Selector_name,'/',num2str(j)), strcat(Whole_name,'/1'));
        
        if Radar_Flag==1
        %%%% Selection of Bus selector with Position for every bus selector of every sensor
        if contains(Sens_obj,'OBJ')
        add_line(Output_model_name, strcat(Bus_Selector_name,'/',num2str(j)), strcat(cell2mat(Bus_Selector_name2i(j)),'/1'));
        end
        end
    end  %%% end of the drawing line for loop at line 128
end  %%% end of the main for loop of input signal at line  69
