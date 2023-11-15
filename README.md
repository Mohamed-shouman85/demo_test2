# Generation Blocks and Wires in Simulink Model From *.m file

The main code is "Read Simulink Model.m", which is designed to check the number of outputs of the Bus selector3 in the Simulink model "First_HIL_Scenario2.mdl" at Veh_1 subsystem -> Algorithm Subsystem.

It estimates the number of outputs from the bus selector and generates a new Simulink model that uses the outputs from the scope and creates an equivalent number of output blocks and wires automatically without the need to use it manually.
