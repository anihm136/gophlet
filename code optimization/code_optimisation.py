#!/usr/bin/env python
# coding: utf-8

import re

'''
Expected o/p:

    icg_test0:    
        a = x * x
        f = a + a
        g = b * f
        
    icg_test1:
        p = a + c
        r = b * b
        
    icg_test2:
        T6 = 4 * i
        x = a[T6]
        T8 = 4 * j
        T9 = a[T8]
        a[T6] = T9
        a[T8] = x
        goto B2


'''

arith_op = ['+','-','*','/']
logic_op = ['<','>','<=','>=','==','!=']
rel_op = ['&&','||']
keywords = ['IF','FALSE','GOTO','print']
is_level = lambda s : bool(re.match(r"^L[0-9]*$", s)) 
is_temp = lambda s : bool(re.match(r"^T[0-9]*$", s)) 
is_id = lambda s : bool(re.match(r"^[A-Za-z][A-Za-z0-9_]*$", s)) 
is_num = lambda s: bool(re.match(r"^[0-9]*(\.)?[0-9]*$", s))
is_bool = lambda s: bool(re.match(r"^(true|false)$", s))

def printICG(list_of_lines):

    
    for line in list_of_lines:
        line = line.strip('\n')
        print(line)
    print()


def algebric_identity(tokens):
    '''
    Checks if it expr is algebric identity in the ICG
    eg.
    BEFORE:
        T1 = x + 0
        T3 = 0 * x
        T5 = x && true
    AFTER:
        T1 = x
        T3 = 0
        T5 = x
    '''

    new_line = ''
    if( tokens[3] == '+' ):
        
        if( tokens[2] == '0' ):                    
            new_line = [tokens[0], '=', tokens[4]]
            new_line = ' '.join(new_line)
                        
        elif( tokens[4] == '0' ):
            new_line = [tokens[0], '=', tokens[2]]
            new_line = ' '.join(new_line)
            
        else:
            new_line = ' '.join(tokens)
            
    elif( tokens[3] == '*' ):

        if( tokens[2] == '0' or tokens[4] == '0' ):
            new_line = [tokens[0], '=', '0']
            new_line = ' '.join(new_line)
            
        elif( tokens[2] == '1' ):
            new_line = [tokens[0], '=', tokens[4]]
            new_line = ' '.join(new_line)
            
        elif( tokens[4] == '1' ):
            new_line = [tokens[0], '=', tokens[2]]
            new_line = ' '.join(new_line)
        
        else:
            new_line = ' '.join(tokens)
            
    elif( tokens[3] == '/' and (tokens[2] == '0' and tokens[3] != '0')):
        
        new_line = [tokens[0], '=', '0']
        new_line = ' '.join(new_line)
            
    elif( tokens[3] == '&&'):
        
        if(tokens[2] == 'true'):
            new_line = [tokens[0], '=', tokens[4]]
            new_line = ' '.join(new_line)
            
        elif(tokens[4] == 'true'):
            new_line = [tokens[0], '=', tokens[2]]
            new_line = ' '.join(new_line)
            
        else:
            new_line = ' '.join(tokens)
    
    elif( tokens[3] == '||'):
        
        if(tokens[2] == 'false'):
            new_line = [tokens[0], '=', tokens[4]]
            new_line = ' '.join(new_line)
            
        elif(tokens[4] == 'false'):
            new_line = [tokens[0], '=', tokens[2]]
            new_line = ' '.join(new_line)
        
        else:
            new_line = ' '.join(tokens)
            
    else:
        new_line = ' '.join(tokens)
        
    return new_line



def const_FP(list_of_lines):
    
    flag1 = 1
    flag2 = 1
    
    const_fold_list, flag1 = constant_folding(list_of_lines)
    const_prop_list, flag2 = constant_propagation(const_fold_list)
    
    
    while( flag1 == 1 or flag2 == 1):
        
        const_fold_list, flag1 = constant_folding(const_prop_list,const_fold_list)
        const_prop_list, flag2 = constant_propagation(const_fold_list,const_prop_list)
        
    return const_prop_list



def constant_folding(list_of_lines, comp=[]):
    
    final_list=[]
    for line in list_of_lines:
        line = line.strip('\n')
        tokens = line.split(' ')
        if(len(tokens) == 5):
            
            if( (tokens[3] in arith_op) and (is_num(tokens[2]) and is_num(tokens[4])) ):
                
                new_line = [tokens[0], '=', str(eval(tokens[2]+tokens[3]+tokens[4]))]
                new_line = ' '.join(new_line)
                final_list.append(new_line)
                
            elif( (tokens[3] in logic_op) and (is_num(tokens[2]) and is_num(tokens[4])) ):
                
                new_line = [tokens[0], '=', str(eval(tokens[2]+tokens[3]+tokens[4]))]
                new_line = ' '.join(new_line)
                final_list.append(new_line)
         
            else:
                
                if ( not (is_id(tokens[2]) and is_id(tokens[4])) ):
                    new_line = algebric_identity(tokens)
                    final_list.append(new_line) 
                    
                else:
                    final_list.append(line)
        else:
            final_list.append(line)
                    
    if( list_of_lines == comp ):
        return (final_list, 0)
    else:
        return (final_list, 1)



def constant_propagation(list_of_lines,comp=[]):

    
    temp = dict()    
    final_list = []
    for line in list_of_lines:
        
        line = line.strip('\n')
        tokens = line.split()
        if( len(tokens) == 3 and tokens[1] == '=' and is_num(tokens[2]) ):
            
            temp[tokens[0]] = tokens[2]
            new_line = ' '.join(tokens)
            final_list.append(new_line)
            
        elif( len(tokens) == 3 and tokens[1] == '=' and tokens[2] in temp ):
            
            new_line = [tokens[0], '=', temp[tokens[2]]]
            new_line = ' '.join(new_line)
            final_list.append(new_line)
            
            temp[tokens[0]] = temp[tokens[2]]
                   
        elif( len(tokens) == 5 ):
            
            if( tokens[2] in temp ):
                tokens[2] = temp[tokens[2]]
                
            if( tokens[4] in temp ):
                tokens[4] = temp[tokens[4]]
                
            if( tokens[0] in temp ):
                temp.pop(tokens[0])
            
            new_line = ' '.join(tokens)
            final_list.append(new_line)
            
        else:
            
            final_list.append(line)      
    
    if(final_list == comp):
        return (final_list, 0)
    else:
        return (final_list, 1)
    
                
def strength_reduction(list_of_lines, comp=[]):
    
    final_list = []
    for line in list_of_lines:
        
        line = line.strip('\n')
        tokens = line.split(' ')
        
        if( len(tokens) == 5 ):
            
            if( tokens[3] == '**' and tokens[4] == '2'):                
                new_line = [tokens[0], '=', tokens[2], '*', tokens[2]]
                new_line = ' '.join(new_line)
                final_list.append(new_line)
                
            elif( tokens[3] == '*' and tokens[4] == '2'):
                new_line = [tokens[0], '=', tokens[2], '+', tokens[2]]
                new_line = ' '.join(new_line)
                final_list.append(new_line)
            
            elif( tokens[3] == '/' and tokens[4] == '2'):
                new_line = [tokens[0], '=', tokens[2], '>>', '1']
                new_line = ' '.join(new_line)
                final_list.append(new_line)
                            
            else:
                final_list.append(line)
        else:
            final_list.append(line)
        
    
    if(final_list == comp):
        return (final_list, 0)
    else:
        return (final_list, 1)
                            
            
def copy_propagation(list_of_lines, comp=[]):
    
    final_list = []
    temp = {}
    for line in list_of_lines:
        
        line = line.strip('\n')
        tokens = line.split(' ')
        
        if( len(tokens) == 3 ):
            if (tokens[2] not in temp) and                (is_id(tokens[2]) or is_temp(tokens[2])):
                        
                temp[tokens[0]] = tokens[2]
                new_line = line
        
            elif( tokens[2] in temp ):
            
                tokens[2] = temp[tokens[2]]
#                 new_line = ' '.join(tokens)
#                 final_list.append(new_line)
                
                temp[tokens[0]] = temp[tokens[2]]
                
            if( '[' in tokens[2] ):
                
                t = tokens[2]
                t = t.split('[')[1]
                t = t.split(']')[0]
                
                if( t in temp ):
                    tokens[2] = tokens[2].replace(t, temp[t])
#                 new_line = ' '.join(tokens)
#                 final_list.append(new_line)
                
            if( '[' in tokens[0] ):
                t = tokens[0]
                t = t.split('[')[1]
                t = t.split(']')[0]
                
                if( t in temp ):
                    tokens[0] = tokens[0].replace(t, temp[t])
#                 new_line = ' '.join(tokens)
#                 final_list.append(new_line)
            new_line = ' '.join(tokens)
            final_list.append(new_line)
                
        
        elif( len(tokens) == 5 ):
            
            if( tokens[2] in temp ):                
                tokens[2] = temp[tokens[2]]
                
            if( tokens[4] in temp ):                
                tokens[4] = temp[tokens[4]]
                
            if( tokens[0] in temp ):
                temp.pop(tokens[0])
            
            new_line = ' '.join(tokens)
            final_list.append(new_line)
            

        else:    
            final_list.append(line)
    
    if( final_list == comp ):
        return (final_list, 0)
    else:
        return (final_list, 1)


def next_subexpr(list_of_lines, line, line_no):
    
    token, expr = line
    if( '+' in expr ):
        expr = expr.replace('+', '\+')
        
    elif( '*' in expr ):
        expr = expr.replace('*', '\*')
    
    subexpr_list = []
    for i, line in enumerate(list_of_lines[line_no+1: ]):
        
        line = line.strip('\n')
        if( re.search(expr, line) ):
            subexpr_list.append(i)
    match1 = 'none'     
    for line in list_of_lines[line_no + 1: ]:
        
        line = line.strip('\n')
        tokens = line.split()        
        if(token in tokens[0] and tokens[1] == '='):
            match1 = line + '\n'
            break
            
        else:
            match1 = 'none'
            
    if( match1 == 'none' ):
        return subexpr_list, len(list_of_lines)
    else:
        i1 = list_of_lines[line_no+1: ].index(match1)
        return subexpr_list, i1
    
    
def common_subexpr_elimination(list_of_lines, comp=[]):
    
    final_list = []
    for i, line in enumerate(list_of_lines):
        
        line = line.strip('\n')
        tokens = line.split(' ')
        
        if( len(tokens) == 5):
            expr = line.split(' = ')
            cmn_exprList, index = next_subexpr(list_of_lines, expr, i)
            for j in cmn_exprList:
                if( j >= index ):
                    break
                else:
                    list_of_lines[i + j + 1] = list_of_lines[i + j + 1].replace(expr[1], tokens[0])
        
        else:
            pass
    
    final_list, flag = copy_propagation(list_of_lines)
    
    if( final_list == comp ):
        return (final_list, 0)
    else:
        return (final_list, 1)
    

    

def var_assign_check(list_of_lines, token, line_no):
    

    for line in list_of_lines[line_no + 1: ]:
        
        line = line.strip('\n')
        tokens = line.split()
        
        if(token in tokens[0]):
            match1 = line + '\n'
            break
            
        else:
            match1 = 'none'
            
            
    for line in list_of_lines[line_no + 1: ]:
        
        line = line.strip('\n')
        tokens = line.split()
        
        if( len(tokens) == 3 and (token in tokens[2]) ):
            match2 = line + '\n'
            break
        
        elif( len(tokens) == 4 ):     #for condtitonal jumps
            match2 = 'none'
            pass
        
        elif( len(tokens) == 5 and ( token == tokens[2] or token == tokens[4]) ):
            match2 = line + '\n'
            break
        else:
             match2 = 'none'
             
    

    if( match2 == 'none' ):
        return 1
    else:
             
        if( match1 == 'none'):
            return 0
             
        else:
            
            i1 = list_of_lines[line_no+1: ].index(match1)
            i2 = list_of_lines[line_no+1: ].index(match2)
            if( i1 < i2 ):
                return 1
            else:
                return 0
         
    


def dead_code_elimination(list_of_lines):
    
    final_list = []
    for i, line in enumerate(list_of_lines[:-1]):
        
        line = line.strip('\n')
        tokens = line.split()
        if( len(tokens) == 3 and tokens[1] == '=' and (is_num(tokens[2]) or is_bool(tokens[2])) ):
            pass
        
        elif( len(tokens) == 3 and re.match('[a-zA-z]\w*\[[a-zA-Z]\w*\]', tokens[0]) ):
            final_list.append(line)
            
        elif( len(tokens) == 3 and tokens[1] == '=' ):
            
            flag = var_assign_check(list_of_lines, tokens[0], i)
            if (flag == 1):
                 pass
            else:
                final_list.append(line)
        else:
            final_list.append(line)
            
    final_list.append(list_of_lines[-1])
    
    return final_list



if( __name__ == '__main__'):
    
    #filename = input("Enter file name: ")
    filename = 'icg_test2.txt'
    f = open(filename, 'r')

    list_of_lines = f.readlines()
    print('-'*27,"ICG" , '-'*27)
    printICG(list_of_lines)
    
    sr_list, flagsr = strength_reduction(list_of_lines)
    print('-'*17,'Strength Reduction Done', '-'*17)
    printICG(sr_list)
    
    fp_list = const_FP(sr_list)        
    print('-'*5,'Constant Propagation and Constant Folding Done', '-'*5)
    printICG(fp_list)

    cp_list, flagcp = copy_propagation(fp_list)
    print('-'*20,'Copy Propagation Done', '-'*20)
    printICG(cp_list)
    
    cse_list, flagcp = common_subexpr_elimination(cp_list)
    print('-'*12,'Common Sub-expression Elimination Done', '-'*12)
    printICG(cse_list)
    
    cse_list, flagcp = copy_propagation(cse_list)
    print('-'*20,'Copy Propagation Done', '-'*20)
    printICG(cse_list)
    
    dce_list = dead_code_elimination(cse_list)
    print('-'*19,'Dead Code Elimination Done', '-'*19)
    printICG(dce_list)
    
    

