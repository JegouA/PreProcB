function tfNorm = zSOI_normalisation(tfSZ, tfBG)
%%%Function to do normalisation z-score with the baseline from seizure%%%

mu = mean(tfBG, 2);
sigma = std(tfBG, [], 2);
tfNorm = bsxfun(@minus, tfSZ, mu);
tfNorm = bsxfun(@rdivide, tfNorm, sigma);

end