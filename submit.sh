#!/bin/bash
#SBATCH --job-name=samplegen_submission
#SBATCH --output=output_mega.log
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1
#SBATCH --time=12:00:00

#name we want the SNR file to have
filename="GW170817_design"

#name of the template file to use. irrelevant if you are using a template bank file
#template="default_templates"
#template="broad_mass_range"
#template="20_templates_broad_10s"

#name of the template bank file to use. if you're using this, disable using normal templates.
#bank="BNS_params.txt"

waveform_params="waveform_params_NS"

#set to 0 for no early warning
#neglat_seconds=0

#number of samples we want
sample_target=100000

#number of samples we want per job (determined through testing. my samples are very large so I'm only doing 250)
#to ensure you end up with exactly the number of samples you want, make sure this is divisible by the target.
#samples_per_file=250
samples_per_file=2000


#number of jobs to have running at a time (excluding this one)
#max_running_jobs=10
max_running_jobs=30


#if astropy throws a warning just run astropy.time.update_leap_seconds() in the terminal.

#rm output/merged_SNR_signal_${filename}.hdf

i=0

#temporary file which allows this process to check how many have been successful
echo 0 > total_samples.txt

while [ $(cat total_samples.txt) -lt $sample_target ]

#for ((i=0;i<${idx};i++))
do

    #names of possible jobs
    joblist=$(eval echo gen_{0..$i}_${filename} | tr ' ' ,)

    #check if there are sufficient jobs running, if not add another one.        
    if [ $(squeue --me -n $joblist -h -t pending,running -r | wc -l) -lt $max_running_jobs ]; then


        #building the json file

        #seed is guaranteed to be different as it's the time when this file is created, with a minimum 2s delay between files.
        seed=$(date +%s)

            echo '{
"random_seed": '$seed',
"template_random_seed": 11,
"background_data_directory": null,
"dq_bits": [0, 1, 2, 3],
"inj_bits": [0, 1, 2, 4],
"waveform_params_file_name": "'${waveform_params}'.ini",
"max_runtime": 6000,
"n_injection_samples": '$samples_per_file',
"n_noise_samples": 0,
"n_processes": 20,
"n_template_samples": 0,
"snr_output_cutoff_low": 99,
"snr_output_cutoff_high": 101,
"snr_output_cutoff_variation": 0,
"output_file_name": "BNS_'${filename}'_15_secs_'${i}'.hdf",
"snr_output_file_name": "SNR_'${filename}'_15_secs_'${i}'.hdf",
"template_output_file_name": "'${template}'.hdf",
"template_bank": "'${bank}'"
}
' > config_files/params_${i}.json

echo '

import h5py

from SampleFileTools1 import SampleFile

obj_test = SampleFile()
obj_test.read_hdf("/fred/oz016/Chayan/samplegen/output/BNS_'${filename}'_15_secs_'${i}'.hdf")
df_test = obj_test.as_dataframe(True,True,True,False) #creating the dataframe from the hdf file.

m1 = df_test["mass1"].values
m2 = df_test["mass2"].values
ra = df_test["ra"].values
dec = df_test["dec"].values
inj_snr = df_test["injection_snr"].values
distance = df_test["distance"].values
h1_snr = (df_test["h1_snr"]*df_test["scale_factor"]).values
l1_snr = (df_test["l1_snr"]*df_test["scale_factor"]).values
v1_snr = (df_test["v1_snr"]*df_test["scale_factor"]).values
spin1z = df_test["spin1z"].values
spin2z= df_test["spin2z"].values
inclination = df_test["inclination"].values

f1 = h5py.File("/fred/oz016/Chayan/samplegen/output/default_'${filename}'_15_sec_parameters_'${i}'.hdf", "w")
f1.create_dataset("mass1", data=m1)
f1.create_dataset("mass2", data=m2)
f1.create_dataset("ra", data=ra)
f1.create_dataset("dec", data=dec)
f1.create_dataset("spin1z", data=spin1z)
f1.create_dataset("spin2z", data=spin2z)
f1.create_dataset("H1_SNR", data=h1_snr)
f1.create_dataset("L1_SNR", data=l1_snr)
f1.create_dataset("V1_SNR", data=v1_snr)
f1.create_dataset("Injection_SNR", data=inj_snr)
f1.create_dataset("distance", data=distance)
f1.create_dataset("inclination", data=inclination)

print("Injection file created")

f1.close()
' > /fred/oz016/Chayan/samplegen/GW_injection_params_${i}.py


            echo "#!/bin/bash
#SBATCH --job-name=gen_'${i}'_'${filename}'
#SBATCH --output=output_'${filename}'_'${i}'.log
#SBATCH --ntasks=20
#SBATCH --ntasks-per-node=20
#SBATCH --time=4:00:00
#SBATCH --mem-per-cpu=9gb

source ~/.bashrc

load_py2

module load python/2.7.14
source /fred/oz016/Chayan/venv/bin/activate

cd /fred/oz016/Chayan/samplegen


python generate_sample.py --config-file=params_${i}.json --negative-latency=15


python generate_snr_series.py --config-file=params_${i}.json --filter-templates=False --negative-latency=15

expr \$(cat total_samples.txt) + ${samples_per_file} > total_samples.txt

echo updating total samples file

python GW_injection_params_${i}.py > Injection_parameters/output_${i}.log

rm -r /fred/oz016/Chayan/samplegen/output/BNS_${filename}_15_secs_${i}.hdf" > submit_${filename}_${i}.sh


        jid=$(sbatch --parsable "submit_${filename}_${i}".sh)
        echo ${jid}
        echo $i

        ((i++))

        sleep 2

    fi

done
    
