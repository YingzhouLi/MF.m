function MF = Factorization(MF,A)
% FACTORIZATION Multifrontal factorization
%   MF = FACTORIZATION(MF,A) factorizes the matrix A as a data-sparse
%   multiplication of lower or upper trangular matrices. If A is a
%   numerically symmetric matrix, A is factorized as
%       L_1 L_2 ... L_k D L_k^T ... L_2^T L_1^T,
%   where L_i is lower trangular matrix. If A is a pattern symmetric
%   matrix, A is factorized as
%       A = L_1 L_2 ... L_k U_k ... U_2 U_1,
%   where L_i is lower trangular matrix and U_j is upper trangular matrix.
%
%   See also SYMBOLMF, MULTIFRONTAL.

%   Copyright 2016 Yingzhou Li, Stanford University

if MF.symm == 1
    [MF.Ltree,MF.Dtree] = ...
        SymmFactorizationRecursion(MF.symboltree);
elseif MF.symm == 2
    [MF.Ltree,MF.Utree] = ...
        PatSymmFactorizationRecursion(MF.symboltree);
end

%====================================================================
    function [Ltree,Dtree,extidx,Aupdate] = ...
            SymmFactorizationRecursion(Stree)
        
        if strcmpi(Stree.type,'node')
            [Ltree.ltree,Dtree.ltree,lidx,lA] = ...
                SymmFactorizationRecursion(Stree.ltree);
            
            [Ltree.rtree,Dtree.rtree,ridx,rA] = ...
                SymmFactorizationRecursion(Stree.rtree);
            
            [cidx,cA] = MergeUpdate(lidx,lA,ridx,rA);
        else
            cidx = [];
            cA = [];
        end
        
        idx = Stree.idx;
        actidx = Stree.actidx;
        
        [Aidx,Aact,Aupdate] = ExtUpdate(idx,actidx,cidx,cA);
        
        [L,D] = ldl(full(Aidx));
        
        ALDinv = Aact/L'/D;
        
        extidx = actidx;
        Aupdate = Aupdate - ALDinv/L*Aact';
        
        Ltree.Mat = L;
        Ltree.AMatinv = ALDinv;
        Dtree.Mat = D;
        
    end

%====================================================================
    function [Ltree,Utree,extidx,Aupdate] = ...
            PatSymmFactorizationRecursion(Stree)
        
        if strcmpi(Stree.type,'node')
            [Ltree.ltree,Utree.ltree,lidx,lA] = ...
                PatSymmFactorizationRecursion(Stree.ltree);
            
            [Ltree.rtree,Utree.rtree,ridx,rA] = ...
                PatSymmFactorizationRecursion(Stree.rtree);
            
            [cidx,cA] = MergeUpdate(lidx,lA,ridx,rA);
        else
            cidx = [];
            cA = [];
        end
        
        idx = Stree.idx;
        actidx = Stree.actidx;
        
        [Aidx,Aactidx,Aidxact,Aupdate] = PatExtUpdate(idx,actidx,cidx,cA);
        
        [L,U] = lu(Aidx);
        
        AUinv = Aactidx/U;
        ALinv = (L\Aidxact)';
        
        extidx = actidx;
        Aupdate = Aupdate - AUinv*ALinv';

        Ltree.Mat = L;
        Ltree.AMatinv = AUinv;
        Utree.Mat = U';
        Utree.AMatinv = ALinv;
        
    end

%====================================================================
    function [idx,A] = MergeUpdate(lidx,lA,ridx,rA)
        
        llen = length(lidx);
        rlen = length(ridx);
        [idx,~,IC] = unique([lidx,ridx],'stable');
        lI = IC(1:llen);
        rI = IC(llen+1:llen+rlen);
        A = zeros(length(idx));
        A(lI,lI) = A(lI,lI) + lA;
        A(rI,rI) = A(rI,rI) + rA;
        
    end

    function [Aidx,Aact,Aupdate] = ExtUpdate(idx,actidx,cidx,cA)
        
        Aidx = full(A(idx,idx));
        Aact = full(A(actidx,idx));
        Aupdate = zeros(length(actidx));
        
        [~,iicI,cicI] = intersect(idx,cidx,'stable');
        [~,aacI,cacI] = intersect(actidx,cidx,'stable');
        Aidx(iicI,iicI) = Aidx(iicI,iicI) + cA(cicI,cicI);
        Aact(aacI,iicI) = Aact(aacI,iicI) + cA(cacI,cicI);
        Aupdate(aacI,aacI) = cA(cacI,cacI);
        
    end

    function [Aidx,Aactidx,Aidxact,Aupdate] = ...
            PatExtUpdate(idx,actidx,cidx,cA)
        
        Aidx = full(A(idx,idx));
        Aactidx = full(A(actidx,idx));
        Aidxact = full(A(idx,actidx));
        Aupdate = zeros(length(actidx));
        
        [~,iicI,cicI] = intersect(idx,cidx,'stable');
        [~,aacI,cacI] = intersect(actidx,cidx,'stable');
        Aidx(iicI,iicI) = Aidx(iicI,iicI) + cA(cicI,cicI);
        Aactidx(aacI,iicI) = Aactidx(aacI,iicI) + cA(cacI,cicI);
        Aidxact(iicI,aacI) = Aidxact(iicI,aacI) + cA(cicI,cacI);
        Aupdate(aacI,aacI) = cA(cacI,cacI);
        
    end

end