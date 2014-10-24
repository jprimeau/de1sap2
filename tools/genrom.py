import re

rom_opcode = ['XX'] * 256
rom_state = ['XX'] * 256
rom_control = ['XX'] * 256

tmp_state = []
tmp_ctrl = []
ref_ctrl = []
state_list = []
l_opcode = ''

with open("./input.dat") as f:
    for line in f.readlines():
        line = re.sub(r'\r\n', r'', line)
        cols = re.split(r'\t+', line)
        c_opcode = cols[0]
        c_con1 = cols[1]
        c_con2 = cols[2]
        tmp_ctrl.append(c_con1+c_con2)
        if c_opcode != '':
            idx = int(c_opcode, 16)
            rom_opcode[idx] = c_opcode
            l_opcode = c_opcode
            tmp_state.append(c_opcode)
        else:
            tmp_state.append('XX')
        state_list.append(l_opcode)

rom_state = tmp_ctrl
ref_ctrl = list(set(tmp_ctrl))

for opcode in rom_opcode:
    if opcode != 'XX':
        idx = rom_opcode.index(opcode)
        rom_opcode[idx] = "{0:0{1}X}".format(tmp_state.index(opcode) * 2, 2)
    
last_state = 0
addr = 0
next_state = 0
l_opcode = ''
for ctrl in rom_state:
    idx = rom_state.index(ctrl)
    addr += 2
    if idx < len(state_list)-1:
        next_idx = idx+1
    else:
        next_idx = 0
    if state_list[next_idx] == state_list[idx] and next_idx != 0:
        next_state = addr
    elif idx == 2:
        next_state = 255 # Fetch done, use I_reg value as opcode index
    else:
        next_state = 0
    ctrl_addr = "{0:0{1}X}".format(ref_ctrl.index(ctrl) * 2, 2)
    rom_state[idx] = [ctrl_addr, next_state]
    l_opcode = state_list[idx]
    
len_rom_opcode = len(rom_opcode)
if len_rom_opcode < 256:
	for i in range(len_rom_opcode, 256):
		rom_opcode.append('00')
		
len_rom_state = len(rom_state)
if len_rom_state < 256:
	for i in range(len_rom_state, 256 / 2):
		rom_state.append(['00', 0])
		
len_ref_ctrl = len(ref_ctrl)
if len_ref_ctrl < 256:
	for i in range(len_ref_ctrl, 256 / 2):
		ref_ctrl.append('0000')
	
addr = 0
cnt = 0
for opcode in rom_opcode:
    if opcode == 'XX':
        opcode = '00'
    print 'x"'+opcode+'",',
    if cnt == 7:
        addr_str = "{0:0{1}X}".format(addr, 2)
        print '-- '+addr_str+'H'
        cnt = 0
        addr += 8
    else:
        cnt += 1

print
    
addr = 0
cnt = 0
for state in rom_state:
    ctrl_addr = str(state[0])
    next_addr = "{0:0{1}X}".format(state[1], 2)
    print 'x"'+ctrl_addr+'", '+'x"'+next_addr+'",',
    if cnt == 3:
        addr_str = "{0:0{1}X}".format(addr, 2)
        print '-- '+addr_str+'H'
        cnt = 0
        addr += 8
    else:
        cnt += 1

print

addr = 0
cnt = 0
for ctrl in ref_ctrl:
    con1 = ctrl[0:2]
    con2 = ctrl[2:4]
    print 'x"'+con1+'", '+'x"'+con2+'",',
    if cnt == 3:
        addr_str = "{0:0{1}X}".format(addr, 2)
        print '-- '+addr_str+'H'
        cnt = 0
        addr += 8
    else:
        cnt += 1