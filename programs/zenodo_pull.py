#need an empirical distribution of download and view numbers for zenodo packages
import requests
import csv
import os

FIELDS = 'id metadata/doi metadata/title created revision stats/downloads stats/views stats/unique_downloads stats/unique_views stats/volume stats/version_volume'.split()
collection = 'aeajournals'
# collection = 'restud-replication'
outputdir = "../data/zenodo"

def get_field(json, field):
    parts = field.split('/')
    subtree = json
    for part in parts:
        subtree = subtree[part]
    return subtree

def filter_fields(json, fields):
    return {key.split('/')[-1]: get_field(json, key) for key in fields}

def get_collection(collection):
    URL = f'https://zenodo.org/api/records?communities={collection}&size=999'
    data = requests.get(URL).json()
    return data
    
def get_stats(json):
    return [filter_fields(row, FIELDS) for row in json['hits']['hits']]
  
def compute_sums(json):
    records = json['hits']['hits']
    total_size = sum([sum([file['size'] for file in record['files']]) for record in records])
    total_count = sum([len(record['files']) for record in records])
    # print the results
    print('Total size of all files: {} bytes'.format(total_size))
    print('Total count of all files: {}'.format(total_count))
    return [total_size, total_count]

def main():
    rawdata     = get_collection(collection)
    # write out stats
    zenodo_data = get_stats(rawdata)
    zenodo = csv.DictWriter(open(os.path.join(outputdir,'zenodo_data_2022.csv'),'wt'), fieldnames=list(zenodo_data[0].keys()))
    zenodo.writeheader()
    
    for row in zenodo_data:
        zenodo.writerow(row)
    
    # compute file counts and filesize sums
    
    with open(os.path.join(outputdir,'zenodo_data_2022_summary.csv'),'wt', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['sumsize', 'filecount'])
        writer.writerow(compute_sums(rawdata))
    
    


if __name__== '__main__':
    main()
