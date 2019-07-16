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

def convert_to_hex_representations(map_data):
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
            first = hex(int(first))[2:]

        second = hex(char_array.index(data[1].upper()))[2:]
        
        string += str(first) + str(second)
        
    print('Hex representation: ' + string)

    # with open('result.txt','a+') as f:
    #     f.write(string + '\n')
    #     f.close()
    
    return string


def rle(input_string):
    count = 1
    prev = ''
    lst = []
    for character in input_string:
        if character != prev:
            if prev:
                entry = (prev,count)
                lst.append(entry)
                #print lst
            count = 1
            prev = character
        else:
            count += 1
    else:
        try:
            entry = (character,count)
            lst.append(entry)
            return (lst, 0)
        except Exception as e:
            print("Exception encountered {e}".format(e=e)) 
            return (e, 1)

def lzw(uncompressed):
    """Compress a string to a list of output symbols."""
 
    # Build the dictionary.
    dict_size = 256
    dictionary = {chr(i): i for i in range(dict_size)}
 
    w = ""
    result = []
    for c in uncompressed:
        wc = w + c
        if wc in dictionary:
            w = wc
        else:
            result.append(dictionary[w])
            # Add wc to the dictionary.
            dictionary[wc] = dict_size
            dict_size += 1
            w = c
 
    # Output the code for w.
    if w:
        result.append(dictionary[w])
    return result

def convert_map_data(map_data):
    string = ''
    byte_index = 0
    for data in map_data:
        if data == None or len(data) <= 0:
            break

        if byte_index == 0:
            first = int(data)
            if first > 0:
                string += str(first)

            byte_index += 1
        else:
            second = int(data,16)
            string += alpha_array[second]

            byte_index = 0
        

    print('Converted: ' + string)

    # with open('result.txt','a+') as f:
    #     f.write(string + '\n')
    #     f.close()
    
    return string

def compress_map_data(map_data):
    prev_char = ''
    string = ''
    count = 0
    for i in range(len(map_data)):
        current_char = map_data[i]
        if current_char == 'A':
            count += 1
        else:
            if count > 0:
                string += str(alpha_array[count+15])
                count = 0
            string += current_char

    print('Compressed: ' + string)

    return string

for file_index in range(1,21):
    path = 'levels/level-' + sys.argv[1] + '/' + str('{:03d}'.format(file_index)) + '.txt'
    if not os.path.isfile(path):
        print('Cannot find path: ' + path + '. Exiting...')
        sys.exit()
        
    map_string = open_file(path)

    # test
    # map_string = '-^,->,--,--,1v,-v'
    # end_test
    
    if map_string == '':
        sys.exit()

    map_data = map_string.split(',')
    map_data = pad_map_data(map_data)

    non_compressed_string = ''
    for data in map_data:
        non_compressed_string += data

    print('\nMap ' + str(file_index) + ' string: ' + str(non_compressed_string))

    map_data = convert_to_hex_representations(map_data)
    map_data = convert_map_data(map_data)
    map_data = compress_map_data(map_data)

    # compressed = lzw(map_data)
    # print('\LZW ' + str(len(compressed)) + ': ' + str(compressed))

    # compressed = rle(map_data)
    # if compressed[1] == 0:
    #     print("RLE is {}".format(compressed[0]))
    
# -^->----1v-v
# 050600001707
#  F G A A1H H
#  F G R  1H H
