/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package musicconverter;

import java.util.HashMap;

/**
 *
 * @author santi
 */
public class PSGCommand {
    public static final int REPEAT_COMMAND = 1;
    public static final int END_REPEAT_COMMAND = 2;
    public static final int GOTO_COMMAND = 3;
    public static final int SKIP_COMMAND = 4;
    public static final int MULTISKIP_COMMAND = 5;
    public static final int END_COMMAND = 6;
    public static final int PSG_COMMAND = 7;
    
    public int type;
    public int register;
    public int parameter;
    
    public int last_length = 0;
    
    public PSGCommand(int a_type, int a_register, int a_parameter) {
        type = a_type;
        register = a_register;
        parameter = a_parameter;
    }
    
    
    public int lengthInBytes() throws Exception  {
        switch(type) {
            case REPEAT_COMMAND:
                return 2; 
            case END_REPEAT_COMMAND:
                return 1; 
            case GOTO_COMMAND:
                return 3; 
            case SKIP_COMMAND:
                return 1; 
            case MULTISKIP_COMMAND:
                return 2; 
            case END_COMMAND:
                return 1; 
            case PSG_COMMAND:
                return 2; 
        }
        throw new Exception("Unknown PSGCommand type: " + type);
    }


    public int lastLengthInBytes() throws Exception  {
        return last_length;
    }
    

    public String toString(String label) throws Exception {
        switch(type) {
            case REPEAT_COMMAND:
                return "    db SFX_REPEAT,"+parameter+"\t;; "+lengthInBytes()+"\n"; 
            case END_REPEAT_COMMAND:
                return "    db SFX_END_REPEAT"+"\t;; "+lengthInBytes()+"\n"; 
            case GOTO_COMMAND:
                return "    db SFX_GOTO\n    dw "+label+"+"+parameter+"\t;; "+lengthInBytes()+"\n"; 
            case SKIP_COMMAND:
                return "    db SFX_SKIP"+"\t;; "+lengthInBytes()+"\n"; 
            case MULTISKIP_COMMAND:
                return "    db SFX_MULTISKIP,"+parameter+"\t;; "+lengthInBytes()+"\n"; 
            case END_COMMAND:
                return "    db SFX_END"+"\t;; "+lengthInBytes()+"\n"; 
            case PSG_COMMAND:
                return "    db "+register+","+parameter+"\t;; "+lengthInBytes()+"\n"; 
        }
        throw new Exception("Unknown PSGCommand type: " + type);
    }
    

    public String toString(String label, HashMap<Integer,Integer> registerState) throws Exception {
        switch(type) {
            case REPEAT_COMMAND:
                last_length = 2;
                return "    db SFX_REPEAT,"+parameter+"\t;; "+lengthInBytes()+"\n"; 
            case END_REPEAT_COMMAND:
                last_length = 1;
                return "    db SFX_END_REPEAT"+"\t;; "+lengthInBytes()+"\n"; 
            case GOTO_COMMAND:
                last_length = 3;
                return "    db SFX_GOTO\n    dw "+label+"+"+parameter+"\t;; "+lengthInBytes()+"\n"; 
            case SKIP_COMMAND:
                last_length = 1;
                return "    db SFX_SKIP"+"\t;; "+lengthInBytes()+"\n"; 
            case MULTISKIP_COMMAND:
                last_length = 2;
                return "    db SFX_MULTISKIP,"+parameter+"\t;; "+lengthInBytes()+"\n"; 
            case END_COMMAND:
                last_length = 1;
                return "    db SFX_END"+"\t;; "+lengthInBytes()+"\n"; 
            case PSG_COMMAND:
                {
                    Integer previousValue = registerState.get(register);
                    if (previousValue==null || previousValue!=parameter) {
                        registerState.put(register,parameter);
                        last_length = 2;
                        return "    db "+register+","+parameter+"\t;; "+lengthInBytes()+"\n"; 
                    } else {
                        last_length = 0;
                        return "";
                    }
                }
        }
        throw new Exception("Unknown PSGCommand type: " + type);
    }

    
}
