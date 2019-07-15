char_array = [ '-', '0', 'P', 'F', 'B', '^', '>', 'v', '<', 's', '!', ']', ';', '[', 'x' ]
alpha_array = [ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z' ]

def open_file(level_string):
    map_string = ''
    with open(level_string + '.txt','r') as f:
        lines = []
        line = f.readline()
        lines_count = 0
        while line:
            lines.append(line)
            line = f.readline()
            lines_count += 1

        current_count = 0
        for line in lines:
            if current_count >= lines_count - 5:
                break

            map_string += line.replace('\n','')
            current_count += 1

    return map_string

def pad_map_data(map_data):
    i = 0
    for data in map_data:
        if len(data) == 1:
            map_data[i] = '-' + data

        i += 1

    return map_data

def convert_map_data(map_data):
    string = ''
    a_count = 0
    for data in map_data:
        if data == None or len(data) <= 0:
            break
        
        first = data[0]
        if first == '-':
            first = 0
        else:
            first = int(first)
        
        if first > 0:
            string += str(first)

        second = data[1]
        second = char_array.index(second)

        if second == 0:
            a_count += 1
        else:
            if a_count > 0:
                string += str(a_count)
                
            string += alpha_array[second]
            a_count = 0

    print(string)
    
    return

map_string = open_file('test-1')
if map_string == '':
    sys.exit()
        
map_data = map_string.split(',')
map_data = pad_map_data(map_data)

print(str(map_data))

convert_map_data(map_data)
