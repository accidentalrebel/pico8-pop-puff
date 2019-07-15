char_array = [ '-', '0', 'P', 'F', 'B', '^', '>', 'v', '<', 's', '!', ']', ';', '[', 'x' ]

def open_file():
    map_string = ''
    with open('test-1.txt','r') as f:
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
    for data in map_data:
        if data == None or len(data) <= 0:
            break
        
        first = data[0]
        second = data[1]
        print('Index: ' + second + ': ' + str(char_array.index(second)))
    
    return

map_string = open_file()
if map_string == '':
    sys.exit()
        
map_data = map_string.split(',')
map_data = pad_map_data(map_data)

print(str(map_data))

convert_map_data(map_data)
