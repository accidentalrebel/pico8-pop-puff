import sys
import os.path

char_array = [ '-', '0', 'P', 'F', 'B', '^', '>', 'V', '<', 'S', '!', ']', ';', '[', 'X' ]
alpha_array = [ 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z' ]

def open_file(level_string):
    map_string = ''
    with open(level_string,'r') as f:
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

        f.close()

    return map_string

def pad_map_data(map_data):
    i = 0
    for data in map_data:
        if len(data) == 1:
            map_data[i] = '-' + data

        i += 1

    return map_data

def convert_to_num_representations(map_data):
    string = ''
    a_count = 0
    for data in map_data:
        if data == None or len(data) <= 0:
            break
        
        first = data[0]
        if first == ' ':
            first = '-'

        if first == '-':
            first = char_array.index(first)
        else:
            first = int(first)
        
        second = char_array.index(data[1].upper())
        
        string += str(first) + str(second)
        
    print('Number representation: ' + string)

    # with open('result.txt','a+') as f:
    #     f.write(string + '\n')
    #     f.close()
    
    return string

def convert_map_data(map_data):
    string = ''
    a_count = 0
    byte_index = 0
    for data in map_data:
        if data == None or len(data) <= 0:
            break

        if byte_index == 0:
            first = int(data)
            if first > 0:
                string += str(alpha_array[first + 15])

            byte_index += 1
        else:
            second = int(data)

            if second == 0:
                a_count += 1
            else:
                if a_count > 0:
                    string += str(a_count)

                string += alpha_array[second]
                a_count = 0

            byte_index = 0
        

    print('Compressed: ' + string)

    # with open('result.txt','a+') as f:
    #     f.write(string + '\n')
    #     f.close()
    
    return

for file_index in range(1,21):
    path = 'levels/level-' + sys.argv[1] + '/' + str('{:03d}'.format(file_index)) + '.txt'
    if not os.path.isfile(path):
        print('Cannot find path: ' + path + '. Exiting...')
        sys.exit()
        
    map_string = open_file(path)
    if map_string == '':
        sys.exit()

    map_data = map_string.split(',')
    map_data = pad_map_data(map_data)

    non_compressed_string = ''
    for data in map_data:
        non_compressed_string += data
    
    print('\nMap ' + str(file_index) + ' string: ' + str(non_compressed_string))

    map_data = convert_to_num_representations(map_data)
    convert_map_data(map_data)
