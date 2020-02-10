function runGridSearchLinear(cCellSVM,ss,cmd)

bestcv = 0;
if nargin<2
    ss=15;
end

if nargin<3
    cmd='-s 1 -w0 1 -w1 1 -v 5 -c ';
end

for log2c = -2:2,
    cmd1 = [cmd, num2str(2^log2c)];
    cv = train(cCellSVM.trainingData.class(1,1:ss:end)', sparse(cCellSVM.trainingData.features(1:ss:end,:)), cmd1);
    if (cv >= bestcv),
        bestcv = cv; bestc = 2^log2c;
    end
    fprintf('%g %g (best c=%g)\n', log2c, cv, bestc, bestcv);
end

cCellSVM.trainingParams.cost=bestc;
cCellSVM.trainingParams.gamma=1;